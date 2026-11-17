#pragma once
#include <stddef.h>
#include <stdint.h>

typedef struct Il2CppDomain Il2CppDomain;
typedef struct Il2CppAssembly Il2CppAssembly;
typedef struct Il2CppImage Il2CppImage;
typedef struct Il2CppClass Il2CppClass;
typedef struct Il2CppObject Il2CppObject;
typedef struct Il2CppString Il2CppString;
typedef struct Il2CppArray Il2CppArray;
typedef struct MethodInfo MethodInfo;
typedef struct FieldInfo FieldInfo;

typedef struct {
    Il2CppDomain  *(*domain_get)(void);
    Il2CppDomain  *(*thread_attach)(Il2CppDomain *);
    const Il2CppAssembly **(*domain_get_assemblies)(Il2CppDomain *, size_t *);
    const Il2CppImage *(*assembly_get_image)(const Il2CppAssembly *);
    Il2CppClass   *(*class_from_name)(const Il2CppImage *, const char *, const char *);
    const MethodInfo *(*class_get_method_from_name)(Il2CppClass *, const char *, int);
    FieldInfo     *(*class_get_field_from_name)(Il2CppClass *, const char *);
    size_t         (*field_get_offset)(FieldInfo *);
    Il2CppObject  *(*object_new)(Il2CppClass *);
    Il2CppString  *(*string_new)(const char *);
    Il2CppObject  *(*runtime_invoke)(const MethodInfo *, void *, void **, Il2CppObject **);
} il2cpp_api_t;

extern il2cpp_api_t g_il2;

int il2_init(void);
