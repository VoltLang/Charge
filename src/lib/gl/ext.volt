module lib.gl.ext;


private import lib.gl.types;
private import lib.gl.enums;
private import lib.gl.funcs;
global bool GL_ARB_ES2_compatibility;
global bool GL_ARB_ES3_1_compatibility;
global bool GL_ARB_ES3_2_compatibility;
global bool GL_ARB_ES3_compatibility;
global bool GL_ARB_gpu_shader5;
global bool GL_ARB_sampler_objects;
global bool GL_ARB_shader_group_vote;
global bool GL_ARB_shading_language_420pack;
global bool GL_ARB_shading_language_packing;
global bool GL_ARB_texture_storage;
global bool GL_ARB_timer_query;
extern(System) @loadDynamic {
void glPrimitiveBoundingBoxARB(GLfloat, GLfloat, GLfloat, GLfloat, GLfloat, GLfloat, GLfloat, GLfloat);
}
