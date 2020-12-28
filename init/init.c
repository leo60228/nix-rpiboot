#ifdef INIT_TESTING
#undef INIT_TESTING
#define INIT_TESTING 1
#else
#define INIT_TESTING 0
#endif

#include <arpa/inet.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <sys/mount.h>
#include <sys/socket.h>
#include <sys/wait.h>
#include <sys/prctl.h>
#include <sys/ioctl.h>
#include <netinet/ip.h>
#include <net/if.h>
#include <unistd.h>
#include <fcntl.h>
#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <errno.h>
#include <spawn.h>
#include <signal.h>
#include <ifaddrs.h>

#define P_TRY(msg, x) do { int res = (x); if (res != 0) { perror((msg)); fflush(stderr); sleep(1); return res; } } while (0)
#define R_TRY(x) do { int res = (x); if (res != 0) { return res; } } while (0)

int make_and_mount(const char* fs, const char* path) {
    if (mkdir(path, S_IRWXU | S_IRWXG | S_IROTH | S_IXOTH) == -1 && errno != EEXIST) {
        perror("mkdir");
        return 1;
    }
    P_TRY("mount", mount(fs, path, fs, 0, NULL));
    return 0;
}

int ifaceinit(const char* iface) {
    struct ifreq flagreq = {0};

    int sock = socket(AF_INET, SOCK_DGRAM, 0);
    if (sock == -1) {
        perror("socket");
        return 1;
    }

    strcpy(flagreq.ifr_name, iface);

    if (ioctl(sock, SIOCGIFFLAGS, &flagreq) == -1) {
        perror("SIOCGIFFLAGS");
        close(sock);
        return 1;
    }

    int up = (flagreq.ifr_flags & IFF_UP) != 0;
    printf("%s %i\n", iface, up);

    if (!INIT_TESTING && strcmp(iface, "usb0") == 0) {
        struct ifreq addrreq = {0};
        strcpy(addrreq.ifr_name, iface);

        struct sockaddr_in addr = {0};
        addr.sin_family = AF_INET;
        addr.sin_addr.s_addr = inet_addr("169.254.4.13");
        memcpy(&addrreq.ifr_addr, &addr, sizeof(addr));

        P_TRY("SIOCSIFADDR", ioctl(sock, SIOCSIFADDR, &addrreq));

        flagreq.ifr_flags |= IFF_UP;
        P_TRY("SIOCSIFFLAGS", ioctl(sock, SIOCSIFFLAGS, &flagreq));

        printf("brought up %s\n", iface);
    }

    close(sock);

    return 0;
}

int hwinit() {
    if (!INIT_TESTING) {
        make_and_mount("proc", "/proc");
        make_and_mount("sysfs", "/sys");
        make_and_mount("devtmpfs", "/dev");
        make_and_mount("tmpfs", "/tmp");
        make_and_mount("tmpfs", "/run");
    }

    return 0;
}

int netsetup() {
    struct ifaddrs *addrs, *tmp;
    P_TRY("getifaddrs", getifaddrs(&addrs));
    tmp = addrs;
    while (tmp) {
        if (tmp->ifa_addr && tmp->ifa_addr->sa_family == AF_PACKET) {
            R_TRY(ifaceinit(tmp->ifa_name));
        }
        tmp = tmp->ifa_next;
    }
    freeifaddrs(addrs);
    return 0;
}

int dbgserver() {
    int sock = socket(AF_INET, SOCK_STREAM, IPPROTO_TCP);

    if (sock == -1) {
        perror("socket");
        return 1;
    }

    P_TRY("setsockopt", setsockopt(sock, SOL_SOCKET, SO_REUSEADDR, &(int){1}, sizeof(int)));

    P_TRY("fcntl", fcntl(sock, F_SETFD, FD_CLOEXEC));

    struct sockaddr_in addr = {0};
    addr.sin_family = AF_INET;
    addr.sin_port = htons(8888);
    addr.sin_addr.s_addr = INADDR_ANY;

    P_TRY("bind", bind(sock, (struct sockaddr*) &addr, sizeof(addr)));

    P_TRY("listen", listen(sock, 1));

    puts("listening on 0.0.0.0:8888");

    struct sockaddr_in peer;
    int conn;
    char line[256];
    while ((conn = accept(sock, (struct sockaddr*) &peer, &(socklen_t){sizeof(peer)})) != -1) {
        puts("accepted");
        FILE* stream = fdopen(conn, "r+");
        pid_t pid = 0;
        if (!stream) {
            perror("fdopen");
            continue;
        }
        while (fgets(line, 256, stream) != NULL) {
            if (strcmp(line, "stop\n") == 0) {
                if (pid != 0) {
                    if (kill(pid, SIGKILL) == -1 && errno != ESRCH) {
                        perror("kill");
                        return 1;
                    }
                }
                pid = 0;
            } else if (strcmp(line, "start\n") == 0) {
                if (pid != 0) {
                    if (kill(pid, SIGKILL) == -1 && errno != ESRCH) {
                        perror("kill");
                        return 1;
                    }
                }
                pid = fork();
                if (pid == 0) {
                    P_TRY("prctl", prctl(PR_SET_PDEATHSIG, SIGKILL));
                    P_TRY("dup2", dup2(fileno(stream), STDOUT_FILENO) == -1);
                    P_TRY("dup2", dup2(fileno(stream), STDERR_FILENO) == -1);
                    P_TRY("execvp", execvp(OPENOCD, (char* const[]){OPENOCD, "-f", OPENOCD_SCRIPT, NULL}));
                }
            } else if (strcmp(line, "wait\n") == 0) {
                int status;
                do {
                    wait(&status);
                } while (!WIFEXITED(status) && !WIFSIGNALED(status));
                if (WIFEXITED(status)) {
                    fprintf(stream, "%i\n", WEXITSTATUS(status));
                } else {
                    fprintf(stream, "%i\n", 128 + WTERMSIG(status));
                }
                pid = 0;
            } else {
                if (fputs("?\n", stream) == EOF) {
                    perror("fputs");
                    fclose(stream);
                    continue;
                }
            }
        }
        if (ferror(stream)) {
            perror("fgets");
        }
        if (pid != 0) {
            if (kill(pid, SIGKILL) == -1 && errno != ESRCH) {
                perror("kill");
                return 1;
            }
        }
        fclose(stream);
    }
    perror("accept");
    return 1;
}

int main() {
    R_TRY(hwinit());
    R_TRY(netsetup());
    R_TRY(dbgserver());
    return 0;
}
