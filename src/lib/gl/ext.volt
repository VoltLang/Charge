module lib.gl.ext;


private import lib.gl.types;
private import lib.gl.enums;
private import lib.gl.funcs;
global bool GL_AMD_shader_atomic_counter_ops;
global bool GL_ARB_ES2_compatibility;
global bool GL_ARB_ES3_1_compatibility;
global bool GL_ARB_ES3_2_compatibility;
global bool GL_ARB_ES3_compatibility;
global bool GL_ARB_explicit_attrib_location;
global bool GL_ARB_sampler_objects;
global bool GL_ARB_shader_atomic_counter_ops;
global bool GL_ARB_shader_ballot;
global bool GL_ARB_texture_storage;
extern(System) @loadDynamic {
void glPrimitiveBoundingBoxARB(GLfloat, GLfloat, GLfloat, GLfloat, GLfloat, GLfloat, GLfloat, GLfloat);
}
