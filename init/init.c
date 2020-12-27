#include <sys/types.h>
#include <sys/stat.h>
#include <sys/mount.h>
#include <stdio.h>
#include <stdlib.h>
#include <errno.h>

void assert_mkdir(const char* path) {
    int status = mkdir(path, S_IRWXU | S_IRWXG | S_IROTH | S_IXOTH);
    if (status && errno != EEXIST) {
        perror("mkdir");
        exit(1);
    }
}

void mount_special(const char* fs, const char* path) {
    mount(fs, path, fs, 0, NULL);
}

void make_and_mount(const char* fs, const char* path) {
    assert_mkdir(path);
    mount_special(fs, path);
}

int main() {
    mount_special("proc", "/proc");
    mount_special("sysfs", "/sys");
    mount_special("devtmpfs", "/dev");
    mount_special("tmpfs", "/tmp");
    mount_special("tmpfs", "/run");

    puts("Hello, world!");
}
