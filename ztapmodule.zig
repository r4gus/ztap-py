// To understand this code: https://docs.python.org/3/extending/extending.html

const py = @cImport({
    // It is recommended to always define PY_SSIZE_T_CLEAN before including Python.h.
    @cDefine("PY_SSIZE_T_CLEAN", {});
    @cInclude("Python.h");
});

const std = @import("std");

const ztap = @import("libs/ztap/src/main.zig");

const PyArg_ParseTuple = py.PyArg_ParseTuple;
const PyObject = py.PyObject;
const PyTypeObject = py.PyTypeObject;
const PyDict_New = py.PyDict_New;
const PyMethodDef = py.PyMethodDef;
const PyModuleDef = py.PyModuleDef;
const PyModuleDef_Base = py.PyModuleDef_Base;
const PyModule_Create = py.PyModule_Create;
const PyDict_SetItem = py.PyDict_SetItem;
const Py_BuildValue = py.Py_BuildValue;
const METH_VARARGS = py.METH_VARARGS;
const PyVarObject = py.PyVarObject;
const Py_TPFLAGS_DEFAULT = py.Py_TPFLAGS_DEFAULT;
const PyType_GenericNew = py.PyType_GenericNew;
const PyType_Ready = py.PyType_Ready;
const PyModule_AddObject = py.PyModule_AddObject;
const Py_INCREF = py.Py_INCREF;
const Py_DECREF = py.Py_DECREF;

// Would not use "testing" allocator for production
const test_allocator = std.testing.allocator;

// Don't think about using this in production, it probably has bugs + memory leaks
fn ctap_request(self: [*c]PyObject, args: [*c]PyObject) callconv(.C) [*]PyObject {
    _ = self;
    _ = args;
    return Py_BuildValue("i", @as(c_int, 1));

    //var string: [*:0]const u8 = undefined;
    //// TODO: handle errors / unexpected input. Probably not a good idea to silently ignore them.
    //_ = PyArg_ParseTuple(args, "s", &string);

    //// "catch unreachable" tells Zig compiler this can't possibly fail
    //// Of course, it might fail: this is just a benchmark.
    //// Did I mention not to use this in production?
    //var untyped = yaml.Yaml.load(std.testing.allocator, std.mem.sliceTo(string, 0)) catch unreachable;
    //// Free all memory at the end of the current scope
    //defer untyped.deinit();

    //// Our friend "catch unreachable" again :)
    //var map = untyped.docs.items[0].asMap() catch unreachable;

    //var dict = PyDict_New();

    //const keys = map.keys();

    //for (keys) |key| {
    //    const value = map.get(key) orelse unreachable;
    //    var pyKey = Py_BuildValue("s#", @ptrCast([*]const u8, key), key.len);
    //    var valueStr = value.asString() catch unreachable;
    //    const pyValue = Py_BuildValue("s#", @ptrCast([*]const u8, valueStr), valueStr.len);

    //    // TODO: again, we just ignore the potential errors that could happen here.
    //    // Don't do that in real life!
    //    _ = PyDict_SetItem(dict, pyKey, pyValue);
    //}

    //return Py_BuildValue("O", dict);
}

const AuthObject = extern struct {
    ob_base: PyObject,
    // Type-specific fields go here.
};

var AuthType = PyTypeObject{ // see cpython/object.h
    // PyVarObject_HEAD_INIT(NULL, 0)
    .ob_base = PyVarObject{
        .ob_base = PyObject{
            .ob_refcnt = 1,
            .ob_type = null,
        },
        .ob_size = 0,
    },
    .tp_name = "ztap.Auth",
    .tp_doc = "CTAP authenticator object",
    .tp_basicsize = @sizeOf(AuthObject),
    .tp_itemsize = 0,
    .tp_flags = Py_TPFLAGS_DEFAULT,
    .tp_new = PyType_GenericNew,

    .tp_dealloc = null,
    .tp_vectorcall_offset = 0,
    .tp_getattr = null,
    .tp_setattr = null,
    .tp_as_async = null,
    .tp_repr = null,

    // Method suites for standard classes
    .tp_as_number = null,
    .tp_as_sequence = null,
    .tp_as_mapping = null,

    // More standard operations
    .tp_hash = null,
    .tp_call = null,
    .tp_str = null,
    .tp_getattro = null,
    .tp_setattro = null,

    // Function to access object as IO buffer
    .tp_as_buffer = null,

    // Call funtion for all accessible objects
    .tp_traverse = null,

    // delete references to contained objects
    .tp_clear = null,

    .tp_richcompare = null,

    .tp_weaklistoffset = 0,

    // Iterators
    .tp_iter = null,
    .tp_iternext = null,

    .tp_methods = null,
    .tp_members = null,
    .tp_getset = null,

    .tp_base = null,
    .tp_dict = null,
    .tp_descr_get = null,
    .tp_descr_set = null,
    .tp_dictoffset = 0,
    .tp_init = null,
    .tp_alloc = null,
    .tp_free = null, // low-level free-memory routine
    .tp_is_gc = null,
    .tp_bases = null,
    .tp_mro = null,
    .tp_cache = null,
    .tp_subclasses = null,
    .tp_weaklist = null,
    .tp_del = null, // destructor

    .tp_version_tag = 0,

    .tp_finalize = null,
    .tp_vectorcall = null,
};

var ZtapMethods = [_]PyMethodDef{
    PyMethodDef{
        .ml_name = "request",
        .ml_meth = ctap_request,
        .ml_flags = METH_VARARGS,
        .ml_doc = "Send a request to a CTAP2 authenticator.",
    },
    PyMethodDef{ // Sentinel
        .ml_name = null,
        .ml_meth = null,
        .ml_flags = 0,
        .ml_doc = null,
    },
};

var authenticatormodule = PyModuleDef{
    .m_base = PyModuleDef_Base{
        .ob_base = PyObject{
            .ob_refcnt = 1,
            .ob_type = null,
        },
        .m_init = null,
        .m_index = 0,
        .m_copy = null,
    },
    .m_name = "ztap",
    .m_doc = null,
    .m_size = -1,
    .m_methods = &ZtapMethods,
    .m_slots = null,
    .m_traverse = null,
    .m_clear = null,
    .m_free = null,
};

pub export fn PyInit_ztap() ?*PyObject {
    var m: ?*PyObject = undefined;

    if (PyType_Ready(&AuthType) < 0)
        return null;

    m = PyModule_Create(&authenticatormodule);
    if (m == null)
        return null;

    Py_INCREF(&AuthType);
    if (PyModule_AddObject(m, "Auth", @ptrCast(*PyObject, &AuthType)) < 0) {
        Py_DECREF(&AuthType);
        Py_DECREF(m);
        return null;
    }

    return m;
}
