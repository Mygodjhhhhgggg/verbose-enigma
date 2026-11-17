#import "il2cpp.h"
#include <dlfcn.h>
#include <string.h>

il2cpp_api_t g_il2;

static void *sym(const char *n) {
    void *p = dlsym(RTLD_DEFAULT, n);
    if (!p) p = dlsym(RTLD_NEXT, n);
    return p;
}

#define BIND(field, name) \
    do { g_il2.field = (void *)sym(name); if (!g_il2.field) { NSLog(@"[CrewMate+] missing %s", name); bad++; } } while (0)

int il2_init(void) {
    memset(&g_il2, 0, sizeof(g_il2));
    int bad = 0;
    BIND(domain_get, "il2cpp_domain_get");
    BIND(thread_attach, "il2cpp_thread_attach");
    BIND(domain_get_assemblies, "il2cpp_domain_get_assemblies");
    BIND(assembly_get_image, "il2cpp_assembly_get_image");
    BIND(class_from_name, "il2cpp_class_from_name");
    BIND(class_get_method_from_name, "il2cpp_class_get_method_from_name");
    BIND(class_get_field_from_name, "il2cpp_class_get_field_from_name");
    BIND(field_get_offset, "il2cpp_field_get_offset");
    BIND(object_new, "il2cpp_object_new");
    BIND(string_new, "il2cpp_string_new");
    BIND(runtime_invoke, "il2cpp_runtime_invoke");
    return bad ? -1 : 0;
}