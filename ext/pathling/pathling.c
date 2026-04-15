#include "ruby.h"
#include <string.h>

static VALUE rb_cPathling;

/* ---- internal struct ---- */
typedef struct {
    VALUE base;   /* String */
    VALUE parts;  /* Array of String */
    VALUE ext;    /* String or Qnil */
} pathling_t;

static void pathling_mark(void *ptr) {
    pathling_t *p = (pathling_t *)ptr;
    rb_gc_mark(p->base);
    rb_gc_mark(p->parts);
    rb_gc_mark(p->ext);
}

static void pathling_free(void *ptr) {
    xfree(ptr);
}

static size_t pathling_memsize(const void *ptr) {
    return sizeof(pathling_t);
}

static const rb_data_type_t pathling_type = {
    "Pathling",
    { pathling_mark, pathling_free, pathling_memsize },
    0, 0,
    RUBY_TYPED_FREE_IMMEDIATELY,
};

static VALUE pathling_alloc(VALUE klass) {
    pathling_t *p;
    VALUE obj = TypedData_Make_Struct(klass, pathling_t, &pathling_type, p);
    p->base  = rb_str_new_cstr("");
    p->parts = rb_ary_new();
    p->ext   = Qnil;
    return obj;
}

static inline pathling_t *get_pathling(VALUE self) {
    pathling_t *p;
    TypedData_Get_Struct(self, pathling_t, &pathling_type, p);
    return p;
}

/* ---- helpers ---- */

/* "foo/bar/" -> "foo/bar" */
static VALUE str_delete_suffix_slash(VALUE str) {
    long len = RSTRING_LEN(str);
    if (len > 0 && RSTRING_PTR(str)[len - 1] == '/') {
        return rb_str_subseq(str, 0, len - 1);
    }
    return str;
}

/* "/foo/bar" -> "foo/bar" */
static VALUE str_delete_prefix_slash(VALUE str) {
    long len = RSTRING_LEN(str);
    if (len > 0 && RSTRING_PTR(str)[0] == '/') {
        return rb_str_subseq(str, 1, len - 1);
    }
    return str;
}

/* ".html" -> "html" */
static VALUE str_delete_prefix_dot(VALUE str) {
    long len = RSTRING_LEN(str);
    if (len > 0 && RSTRING_PTR(str)[0] == '.') {
        return rb_str_subseq(str, 1, len - 1);
    }
    return str;
}

/* ---- initialize(path = "") ---- */
static VALUE pathling_initialize(int argc, VALUE *argv, VALUE self) {
    VALUE path_arg;
    rb_scan_args(argc, argv, "01", &path_arg);

    pathling_t *p = get_pathling(self);
    VALUE path_str = NIL_P(path_arg) ? rb_str_new_cstr("") : rb_obj_as_string(path_arg);
    p->base  = rb_str_dup(path_str);
    p->parts = rb_ary_new();
    p->ext   = Qnil;
    return self;
}

/* ---- path(*paths) ---- */
static VALUE pathling_path(int argc, VALUE *argv, VALUE self) {
    pathling_t *p = get_pathling(self);
    VALUE new_parts = rb_ary_new_capa(argc);

    for (int i = 0; i < argc; i++) {
        VALUE s = rb_obj_as_string(argv[i]);
        rb_ary_push(new_parts, str_delete_prefix_slash(s));
    }
    p->parts = new_parts;
    return self;
}

/* ---- with_ext(ext) ---- */
static VALUE pathling_with_ext(VALUE self, VALUE ext) {
    pathling_t *p = get_pathling(self);
    VALUE s = rb_obj_as_string(ext);
    p->ext = str_delete_prefix_dot(s);
    return self;
}

/* ---- build ---- */
static VALUE pathling_build(VALUE self) {
    pathling_t *p = get_pathling(self);

    /* parts = [base_no_trailing_slash, *@parts] */
    VALUE parts = rb_ary_dup(p->parts);
    rb_ary_unshift(parts, str_delete_suffix_slash(p->base));

    /* apply extension to last element */
    if (!NIL_P(p->ext)) {
        long last_idx = RARRAY_LEN(parts) - 1;
        VALUE last    = rb_ary_entry(parts, last_idx);

        /* find last '.' — raw pointer use is confined to this read-only scan,
           no allocation occurs inside the loop so ptr stays valid */
        const char *ptr = RSTRING_PTR(last);
        long        len = RSTRING_LEN(last);
        long dot_idx = -1;
        for (long i = len - 1; i >= 0; i--) {
            if (ptr[i] == '.') { dot_idx = i; break; }
        }

        /* rb_str_subseq is GC-safe: takes VALUE + offsets, no raw pointer held
           across an allocation boundary */
        VALUE new_last;
        if (dot_idx >= 0) {
            new_last = rb_str_subseq(last, 0, dot_idx);
        } else {
            new_last = rb_str_dup(last);
        }
        rb_str_cat_cstr(new_last, ".");
        rb_str_append(new_last, p->ext);
        rb_ary_store(parts, last_idx, new_last);
    }

    /* join with "/" */
    VALUE sep    = rb_str_new_cstr("/");
    VALUE result = rb_ary_join(parts, sep);
    OBJ_FREEZE(result);
    return result;
}

/* ---- to_s ---- */
static VALUE pathling_to_s(VALUE self) {
    return pathling_build(self);
}

/* ---- self.wrap(path) ---- */
static VALUE pathling_wrap(VALUE klass, VALUE path) {
    if (rb_obj_is_kind_of(path, klass)) return path;

    VALUE obj = pathling_alloc(klass);
    VALUE argv[] = { path };
    pathling_initialize(1, argv, obj);
    return obj;
}

/* ---- Init ---- */
void Init_pathling(void) {
    rb_cPathling = rb_define_class("Pathling", rb_cObject);
    rb_define_alloc_func(rb_cPathling, pathling_alloc);

    rb_define_method(rb_cPathling, "initialize", pathling_initialize, -1);
    rb_define_method(rb_cPathling, "path",       pathling_path,       -1);
    rb_define_method(rb_cPathling, "with_ext",   pathling_with_ext,    1);
    rb_define_method(rb_cPathling, "build",      pathling_build,       0);
    rb_define_method(rb_cPathling, "to_s",       pathling_to_s,        0);

    rb_define_singleton_method(rb_cPathling, "wrap", pathling_wrap, 1);
}
