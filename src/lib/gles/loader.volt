module lib.gles.loader;

private import lib.gles.funcs;
private import lib.gles.enums;
private import lib.gles.types;


global int GL_MAJOR = 0;
global int GL_MINOR = 0;

private extern(C) char* strstr(const(char)*, const(char)*);
private extern(C) int strcmp(const(char)*, const(char)*);
private extern(C) size_t strlen(const(char)*);

private bool has_ext(const(char)* ext)
{
	const(char)* extensions = cast(const(char)*)glGetString(GL_EXTENSIONS);
	const(char)* loc;
	const(char)* terminator;

	if (extensions is null || ext is null) {
		return false;
	}

	while (true) {
		loc = strstr(extensions, ext);
		if (loc is null) {
			return false;
		}

		terminator = loc + strlen(ext);
		if ((loc is extensions || *(loc - 1) == ' ') &&
		    (*terminator == ' ' || *terminator == '\0')) {
			return true;
		}
		extensions = terminator;
	}

	return false;
}

void gladLoadGLES2(void* function(const(char)* name) load)
{
	glGetString = cast(typeof(glGetString))load("glGetString");
	if(glGetString is null) { return; }

	find_coreGLES2();
	load_GL_ES_VERSION_2_0(load);

	find_extensionsGLES2();
	load_GL_QCOM_tiled_rendering(load);
	load_GL_NV_fence(load);
	load_GL_ANGLE_translated_shader_source(load);
	load_GL_EXT_robustness(load);
	load_GL_NV_draw_instanced(load);
	load_GL_NV_coverage_sample(load);
	load_GL_EXT_disjoint_timer_query(load);
	load_GL_EXT_multi_draw_arrays(load);
	load_GL_QCOM_driver_control(load);
	load_GL_EXT_debug_marker(load);
	load_GL_EXT_multisampled_render_to_texture(load);
	load_GL_ANGLE_framebuffer_multisample(load);
	load_GL_OES_get_program_binary(load);
	load_GL_APPLE_framebuffer_multisample(load);
	load_GL_NV_framebuffer_blit(load);
	load_GL_QCOM_alpha_test(load);
	load_GL_KHR_debug(load);
	load_GL_EXT_occlusion_query_boolean(load);
	load_GL_APPLE_sync(load);
	load_GL_QCOM_extended_get2(load);
	load_GL_EXT_separate_shader_objects(load);
	load_GL_NV_framebuffer_multisample(load);
	load_GL_NV_draw_buffers(load);
	load_GL_EXT_draw_buffers(load);
	load_GL_EXT_debug_label(load);
	load_GL_OES_EGL_image(load);
	load_GL_EXT_blend_minmax(load);
	load_GL_EXT_texture_storage(load);
	load_GL_EXT_map_buffer_range(load);
	load_GL_OES_mapbuffer(load);
	load_GL_AMD_performance_monitor(load);
	load_GL_IMG_multisampled_render_to_texture(load);
	load_GL_APPLE_copy_texture_levels(load);
	load_GL_EXT_multiview_draw_buffers(load);
	load_GL_QCOM_extended_get(load);
	load_GL_ANGLE_framebuffer_blit(load);
	load_GL_OES_texture_3D(load);
	load_GL_NV_read_buffer(load);
	load_GL_NV_instanced_arrays(load);
	load_GL_ANGLE_instanced_arrays(load);
	load_GL_EXT_discard_framebuffer(load);
	load_GL_OES_vertex_array_object(load);

	return;
}

private:

void find_coreGLES2()
{
	const(char)* v = cast(const(char)*)glGetString(GL_VERSION);
	int major = v[0] - '0';
	int minor = v[2] - '0';
	GL_MAJOR = major; GL_MINOR = minor;
	GL_ES_VERSION_2_0 = (major == 2 && minor >= 0) || major > 2;
	return;
}

void find_extensionsGLES2()
{
	GL_NV_sRGB_formats = has_ext("GL_NV_sRGB_formats");
	GL_OES_packed_depth_stencil = has_ext("GL_OES_packed_depth_stencil");
	GL_QCOM_perfmon_global_mode = has_ext("GL_QCOM_perfmon_global_mode");
	GL_QCOM_tiled_rendering = has_ext("GL_QCOM_tiled_rendering");
	GL_OES_texture_half_float_linear = has_ext("GL_OES_texture_half_float_linear");
	GL_NV_fence = has_ext("GL_NV_fence");
	GL_NV_texture_border_clamp = has_ext("GL_NV_texture_border_clamp");
	GL_IMG_texture_compression_pvrtc = has_ext("GL_IMG_texture_compression_pvrtc");
	GL_OES_texture_half_float = has_ext("GL_OES_texture_half_float");
	GL_EXT_sRGB = has_ext("GL_EXT_sRGB");
	GL_QCOM_writeonly_rendering = has_ext("GL_QCOM_writeonly_rendering");
	GL_NV_read_depth_stencil = has_ext("GL_NV_read_depth_stencil");
	GL_ANGLE_translated_shader_source = has_ext("GL_ANGLE_translated_shader_source");
	GL_ANGLE_texture_usage = has_ext("GL_ANGLE_texture_usage");
	GL_AMD_program_binary_Z400 = has_ext("GL_AMD_program_binary_Z400");
	GL_ARM_rgba8 = has_ext("GL_ARM_rgba8");
	GL_EXT_robustness = has_ext("GL_EXT_robustness");
	GL_OES_fbo_render_mipmap = has_ext("GL_OES_fbo_render_mipmap");
	GL_NV_draw_instanced = has_ext("GL_NV_draw_instanced");
	GL_NV_coverage_sample = has_ext("GL_NV_coverage_sample");
	GL_FJ_shader_binary_GCCSO = has_ext("GL_FJ_shader_binary_GCCSO");
	GL_EXT_disjoint_timer_query = has_ext("GL_EXT_disjoint_timer_query");
	GL_OES_compressed_paletted_texture = has_ext("GL_OES_compressed_paletted_texture");
	GL_EXT_shader_texture_lod = has_ext("GL_EXT_shader_texture_lod");
	GL_NV_read_buffer_front = has_ext("GL_NV_read_buffer_front");
	GL_OES_texture_float_linear = has_ext("GL_OES_texture_float_linear");
	GL_NV_fbo_color_attachments = has_ext("GL_NV_fbo_color_attachments");
	GL_IMG_read_format = has_ext("GL_IMG_read_format");
	GL_NV_texture_compression_s3tc_update = has_ext("GL_NV_texture_compression_s3tc_update");
	GL_OES_fragment_precision_high = has_ext("GL_OES_fragment_precision_high");
	GL_EXT_multi_draw_arrays = has_ext("GL_EXT_multi_draw_arrays");
	GL_OES_texture_npot = has_ext("GL_OES_texture_npot");
	GL_EXT_texture_compression_dxt1 = has_ext("GL_EXT_texture_compression_dxt1");
	GL_QCOM_driver_control = has_ext("GL_QCOM_driver_control");
	GL_ANGLE_depth_texture = has_ext("GL_ANGLE_depth_texture");
	GL_KHR_texture_compression_astc_ldr = has_ext("GL_KHR_texture_compression_astc_ldr");
	GL_EXT_debug_marker = has_ext("GL_EXT_debug_marker");
	GL_EXT_multisampled_render_to_texture = has_ext("GL_EXT_multisampled_render_to_texture");
	GL_ANGLE_framebuffer_multisample = has_ext("GL_ANGLE_framebuffer_multisample");
	GL_EXT_color_buffer_half_float = has_ext("GL_EXT_color_buffer_half_float");
	GL_OES_get_program_binary = has_ext("GL_OES_get_program_binary");
	GL_APPLE_framebuffer_multisample = has_ext("GL_APPLE_framebuffer_multisample");
	GL_OES_texture_float = has_ext("GL_OES_texture_float");
	GL_OES_vertex_half_float = has_ext("GL_OES_vertex_half_float");
	GL_NV_framebuffer_blit = has_ext("GL_NV_framebuffer_blit");
	GL_OES_stencil1 = has_ext("GL_OES_stencil1");
	GL_QCOM_alpha_test = has_ext("GL_QCOM_alpha_test");
	GL_ANGLE_pack_reverse_row_order = has_ext("GL_ANGLE_pack_reverse_row_order");
	GL_KHR_debug = has_ext("GL_KHR_debug");
	GL_OES_rgb8_rgba8 = has_ext("GL_OES_rgb8_rgba8");
	GL_EXT_occlusion_query_boolean = has_ext("GL_EXT_occlusion_query_boolean");
	GL_OES_depth_texture = has_ext("GL_OES_depth_texture");
	GL_QCOM_binning_control = has_ext("GL_QCOM_binning_control");
	GL_OES_surfaceless_context = has_ext("GL_OES_surfaceless_context");
	GL_APPLE_sync = has_ext("GL_APPLE_sync");
	GL_IMG_program_binary = has_ext("GL_IMG_program_binary");
	GL_ARM_mali_program_binary = has_ext("GL_ARM_mali_program_binary");
	GL_EXT_shader_framebuffer_fetch = has_ext("GL_EXT_shader_framebuffer_fetch");
	GL_ANGLE_program_binary = has_ext("GL_ANGLE_program_binary");
	GL_EXT_unpack_subimage = has_ext("GL_EXT_unpack_subimage");
	GL_ANGLE_texture_compression_dxt3 = has_ext("GL_ANGLE_texture_compression_dxt3");
	GL_ANGLE_texture_compression_dxt5 = has_ext("GL_ANGLE_texture_compression_dxt5");
	GL_EXT_read_format_bgra = has_ext("GL_EXT_read_format_bgra");
	GL_OES_compressed_ETC1_RGB8_texture = has_ext("GL_OES_compressed_ETC1_RGB8_texture");
	GL_QCOM_extended_get2 = has_ext("GL_QCOM_extended_get2");
	GL_NV_shadow_samplers_cube = has_ext("GL_NV_shadow_samplers_cube");
	GL_APPLE_texture_max_level = has_ext("GL_APPLE_texture_max_level");
	GL_EXT_shadow_samplers = has_ext("GL_EXT_shadow_samplers");
	GL_IMG_shader_binary = has_ext("GL_IMG_shader_binary");
	GL_OES_depth32 = has_ext("GL_OES_depth32");
	GL_EXT_separate_shader_objects = has_ext("GL_EXT_separate_shader_objects");
	GL_NV_framebuffer_multisample = has_ext("GL_NV_framebuffer_multisample");
	GL_NV_draw_buffers = has_ext("GL_NV_draw_buffers");
	GL_NV_read_stencil = has_ext("GL_NV_read_stencil");
	GL_VIV_shader_binary = has_ext("GL_VIV_shader_binary");
	GL_OES_vertex_type_10_10_10_2 = has_ext("GL_OES_vertex_type_10_10_10_2");
	GL_APPLE_rgb_422 = has_ext("GL_APPLE_rgb_422");
	GL_EXT_texture_sRGB_decode = has_ext("GL_EXT_texture_sRGB_decode");
	GL_NV_texture_npot_2D_mipmap = has_ext("GL_NV_texture_npot_2D_mipmap");
	GL_EXT_draw_buffers = has_ext("GL_EXT_draw_buffers");
	GL_EXT_debug_label = has_ext("GL_EXT_debug_label");
	GL_OES_EGL_image = has_ext("GL_OES_EGL_image");
	GL_EXT_texture_filter_anisotropic = has_ext("GL_EXT_texture_filter_anisotropic");
	GL_EXT_blend_minmax = has_ext("GL_EXT_blend_minmax");
	GL_OES_depth24 = has_ext("GL_OES_depth24");
	GL_EXT_texture_storage = has_ext("GL_EXT_texture_storage");
	GL_OES_required_internalformat = has_ext("GL_OES_required_internalformat");
	GL_EXT_sRGB_write_control = has_ext("GL_EXT_sRGB_write_control");
	GL_AMD_compressed_3DC_texture = has_ext("GL_AMD_compressed_3DC_texture");
	GL_OES_element_index_uint = has_ext("GL_OES_element_index_uint");
	GL_IMG_texture_compression_pvrtc2 = has_ext("GL_IMG_texture_compression_pvrtc2");
	GL_EXT_map_buffer_range = has_ext("GL_EXT_map_buffer_range");
	GL_OES_mapbuffer = has_ext("GL_OES_mapbuffer");
	GL_OES_EGL_image_external = has_ext("GL_OES_EGL_image_external");
	GL_APPLE_texture_format_BGRA8888 = has_ext("GL_APPLE_texture_format_BGRA8888");
	GL_AMD_performance_monitor = has_ext("GL_AMD_performance_monitor");
	GL_NV_shadow_samplers_array = has_ext("GL_NV_shadow_samplers_array");
	GL_IMG_multisampled_render_to_texture = has_ext("GL_IMG_multisampled_render_to_texture");
	GL_NV_depth_nonlinear = has_ext("GL_NV_depth_nonlinear");
	GL_EXT_texture_format_BGRA8888 = has_ext("GL_EXT_texture_format_BGRA8888");
	GL_APPLE_copy_texture_levels = has_ext("GL_APPLE_copy_texture_levels");
	GL_ARM_mali_shader_binary = has_ext("GL_ARM_mali_shader_binary");
	GL_EXT_multiview_draw_buffers = has_ext("GL_EXT_multiview_draw_buffers");
	GL_QCOM_extended_get = has_ext("GL_QCOM_extended_get");
	GL_EXT_texture_rg = has_ext("GL_EXT_texture_rg");
	GL_OES_standard_derivatives = has_ext("GL_OES_standard_derivatives");
	GL_OES_stencil4 = has_ext("GL_OES_stencil4");
	GL_ANGLE_framebuffer_blit = has_ext("GL_ANGLE_framebuffer_blit");
	GL_OES_texture_3D = has_ext("GL_OES_texture_3D");
	GL_NV_read_buffer = has_ext("GL_NV_read_buffer");
	GL_NV_generate_mipmap_sRGB = has_ext("GL_NV_generate_mipmap_sRGB");
	GL_DMP_shader_binary = has_ext("GL_DMP_shader_binary");
	GL_NV_instanced_arrays = has_ext("GL_NV_instanced_arrays");
	GL_EXT_texture_type_2_10_10_10_REV = has_ext("GL_EXT_texture_type_2_10_10_10_REV");
	GL_ANGLE_instanced_arrays = has_ext("GL_ANGLE_instanced_arrays");
	GL_EXT_discard_framebuffer = has_ext("GL_EXT_discard_framebuffer");
	GL_NV_read_depth = has_ext("GL_NV_read_depth");
	GL_AMD_compressed_ATC_texture = has_ext("GL_AMD_compressed_ATC_texture");
	GL_OES_vertex_array_object = has_ext("GL_OES_vertex_array_object");
	return;
}

void load_GL_ES_VERSION_2_0(void* function(const(char)* name) load)
{
	if(!GL_ES_VERSION_2_0) return;
	glActiveTexture = cast(typeof(glActiveTexture))load("glActiveTexture");
	glAttachShader = cast(typeof(glAttachShader))load("glAttachShader");
	glBindAttribLocation = cast(typeof(glBindAttribLocation))load("glBindAttribLocation");
	glBindBuffer = cast(typeof(glBindBuffer))load("glBindBuffer");
	glBindFramebuffer = cast(typeof(glBindFramebuffer))load("glBindFramebuffer");
	glBindRenderbuffer = cast(typeof(glBindRenderbuffer))load("glBindRenderbuffer");
	glBindTexture = cast(typeof(glBindTexture))load("glBindTexture");
	glBlendColor = cast(typeof(glBlendColor))load("glBlendColor");
	glBlendEquation = cast(typeof(glBlendEquation))load("glBlendEquation");
	glBlendEquationSeparate = cast(typeof(glBlendEquationSeparate))load("glBlendEquationSeparate");
	glBlendFunc = cast(typeof(glBlendFunc))load("glBlendFunc");
	glBlendFuncSeparate = cast(typeof(glBlendFuncSeparate))load("glBlendFuncSeparate");
	glBufferData = cast(typeof(glBufferData))load("glBufferData");
	glBufferSubData = cast(typeof(glBufferSubData))load("glBufferSubData");
	glCheckFramebufferStatus = cast(typeof(glCheckFramebufferStatus))load("glCheckFramebufferStatus");
	glClear = cast(typeof(glClear))load("glClear");
	glClearColor = cast(typeof(glClearColor))load("glClearColor");
	glClearDepthf = cast(typeof(glClearDepthf))load("glClearDepthf");
	glClearStencil = cast(typeof(glClearStencil))load("glClearStencil");
	glColorMask = cast(typeof(glColorMask))load("glColorMask");
	glCompileShader = cast(typeof(glCompileShader))load("glCompileShader");
	glCompressedTexImage2D = cast(typeof(glCompressedTexImage2D))load("glCompressedTexImage2D");
	glCompressedTexSubImage2D = cast(typeof(glCompressedTexSubImage2D))load("glCompressedTexSubImage2D");
	glCopyTexImage2D = cast(typeof(glCopyTexImage2D))load("glCopyTexImage2D");
	glCopyTexSubImage2D = cast(typeof(glCopyTexSubImage2D))load("glCopyTexSubImage2D");
	glCreateProgram = cast(typeof(glCreateProgram))load("glCreateProgram");
	glCreateShader = cast(typeof(glCreateShader))load("glCreateShader");
	glCullFace = cast(typeof(glCullFace))load("glCullFace");
	glDeleteBuffers = cast(typeof(glDeleteBuffers))load("glDeleteBuffers");
	glDeleteFramebuffers = cast(typeof(glDeleteFramebuffers))load("glDeleteFramebuffers");
	glDeleteProgram = cast(typeof(glDeleteProgram))load("glDeleteProgram");
	glDeleteRenderbuffers = cast(typeof(glDeleteRenderbuffers))load("glDeleteRenderbuffers");
	glDeleteShader = cast(typeof(glDeleteShader))load("glDeleteShader");
	glDeleteTextures = cast(typeof(glDeleteTextures))load("glDeleteTextures");
	glDepthFunc = cast(typeof(glDepthFunc))load("glDepthFunc");
	glDepthMask = cast(typeof(glDepthMask))load("glDepthMask");
	glDepthRangef = cast(typeof(glDepthRangef))load("glDepthRangef");
	glDetachShader = cast(typeof(glDetachShader))load("glDetachShader");
	glDisable = cast(typeof(glDisable))load("glDisable");
	glDisableVertexAttribArray = cast(typeof(glDisableVertexAttribArray))load("glDisableVertexAttribArray");
	glDrawArrays = cast(typeof(glDrawArrays))load("glDrawArrays");
	glDrawElements = cast(typeof(glDrawElements))load("glDrawElements");
	glEnable = cast(typeof(glEnable))load("glEnable");
	glEnableVertexAttribArray = cast(typeof(glEnableVertexAttribArray))load("glEnableVertexAttribArray");
	glFinish = cast(typeof(glFinish))load("glFinish");
	glFlush = cast(typeof(glFlush))load("glFlush");
	glFramebufferRenderbuffer = cast(typeof(glFramebufferRenderbuffer))load("glFramebufferRenderbuffer");
	glFramebufferTexture2D = cast(typeof(glFramebufferTexture2D))load("glFramebufferTexture2D");
	glFrontFace = cast(typeof(glFrontFace))load("glFrontFace");
	glGenBuffers = cast(typeof(glGenBuffers))load("glGenBuffers");
	glGenerateMipmap = cast(typeof(glGenerateMipmap))load("glGenerateMipmap");
	glGenFramebuffers = cast(typeof(glGenFramebuffers))load("glGenFramebuffers");
	glGenRenderbuffers = cast(typeof(glGenRenderbuffers))load("glGenRenderbuffers");
	glGenTextures = cast(typeof(glGenTextures))load("glGenTextures");
	glGetActiveAttrib = cast(typeof(glGetActiveAttrib))load("glGetActiveAttrib");
	glGetActiveUniform = cast(typeof(glGetActiveUniform))load("glGetActiveUniform");
	glGetAttachedShaders = cast(typeof(glGetAttachedShaders))load("glGetAttachedShaders");
	glGetAttribLocation = cast(typeof(glGetAttribLocation))load("glGetAttribLocation");
	glGetBooleanv = cast(typeof(glGetBooleanv))load("glGetBooleanv");
	glGetBufferParameteriv = cast(typeof(glGetBufferParameteriv))load("glGetBufferParameteriv");
	glGetError = cast(typeof(glGetError))load("glGetError");
	glGetFloatv = cast(typeof(glGetFloatv))load("glGetFloatv");
	glGetFramebufferAttachmentParameteriv = cast(typeof(glGetFramebufferAttachmentParameteriv))load("glGetFramebufferAttachmentParameteriv");
	glGetIntegerv = cast(typeof(glGetIntegerv))load("glGetIntegerv");
	glGetProgramiv = cast(typeof(glGetProgramiv))load("glGetProgramiv");
	glGetProgramInfoLog = cast(typeof(glGetProgramInfoLog))load("glGetProgramInfoLog");
	glGetRenderbufferParameteriv = cast(typeof(glGetRenderbufferParameteriv))load("glGetRenderbufferParameteriv");
	glGetShaderiv = cast(typeof(glGetShaderiv))load("glGetShaderiv");
	glGetShaderInfoLog = cast(typeof(glGetShaderInfoLog))load("glGetShaderInfoLog");
	glGetShaderPrecisionFormat = cast(typeof(glGetShaderPrecisionFormat))load("glGetShaderPrecisionFormat");
	glGetShaderSource = cast(typeof(glGetShaderSource))load("glGetShaderSource");
	glGetString = cast(typeof(glGetString))load("glGetString");
	glGetTexParameterfv = cast(typeof(glGetTexParameterfv))load("glGetTexParameterfv");
	glGetTexParameteriv = cast(typeof(glGetTexParameteriv))load("glGetTexParameteriv");
	glGetUniformfv = cast(typeof(glGetUniformfv))load("glGetUniformfv");
	glGetUniformiv = cast(typeof(glGetUniformiv))load("glGetUniformiv");
	glGetUniformLocation = cast(typeof(glGetUniformLocation))load("glGetUniformLocation");
	glGetVertexAttribfv = cast(typeof(glGetVertexAttribfv))load("glGetVertexAttribfv");
	glGetVertexAttribiv = cast(typeof(glGetVertexAttribiv))load("glGetVertexAttribiv");
	glGetVertexAttribPointerv = cast(typeof(glGetVertexAttribPointerv))load("glGetVertexAttribPointerv");
	glHint = cast(typeof(glHint))load("glHint");
	glIsBuffer = cast(typeof(glIsBuffer))load("glIsBuffer");
	glIsEnabled = cast(typeof(glIsEnabled))load("glIsEnabled");
	glIsFramebuffer = cast(typeof(glIsFramebuffer))load("glIsFramebuffer");
	glIsProgram = cast(typeof(glIsProgram))load("glIsProgram");
	glIsRenderbuffer = cast(typeof(glIsRenderbuffer))load("glIsRenderbuffer");
	glIsShader = cast(typeof(glIsShader))load("glIsShader");
	glIsTexture = cast(typeof(glIsTexture))load("glIsTexture");
	glLineWidth = cast(typeof(glLineWidth))load("glLineWidth");
	glLinkProgram = cast(typeof(glLinkProgram))load("glLinkProgram");
	glPixelStorei = cast(typeof(glPixelStorei))load("glPixelStorei");
	glPolygonOffset = cast(typeof(glPolygonOffset))load("glPolygonOffset");
	glReadPixels = cast(typeof(glReadPixels))load("glReadPixels");
	glReleaseShaderCompiler = cast(typeof(glReleaseShaderCompiler))load("glReleaseShaderCompiler");
	glRenderbufferStorage = cast(typeof(glRenderbufferStorage))load("glRenderbufferStorage");
	glSampleCoverage = cast(typeof(glSampleCoverage))load("glSampleCoverage");
	glScissor = cast(typeof(glScissor))load("glScissor");
	glShaderBinary = cast(typeof(glShaderBinary))load("glShaderBinary");
	glShaderSource = cast(typeof(glShaderSource))load("glShaderSource");
	glStencilFunc = cast(typeof(glStencilFunc))load("glStencilFunc");
	glStencilFuncSeparate = cast(typeof(glStencilFuncSeparate))load("glStencilFuncSeparate");
	glStencilMask = cast(typeof(glStencilMask))load("glStencilMask");
	glStencilMaskSeparate = cast(typeof(glStencilMaskSeparate))load("glStencilMaskSeparate");
	glStencilOp = cast(typeof(glStencilOp))load("glStencilOp");
	glStencilOpSeparate = cast(typeof(glStencilOpSeparate))load("glStencilOpSeparate");
	glTexImage2D = cast(typeof(glTexImage2D))load("glTexImage2D");
	glTexParameterf = cast(typeof(glTexParameterf))load("glTexParameterf");
	glTexParameterfv = cast(typeof(glTexParameterfv))load("glTexParameterfv");
	glTexParameteri = cast(typeof(glTexParameteri))load("glTexParameteri");
	glTexParameteriv = cast(typeof(glTexParameteriv))load("glTexParameteriv");
	glTexSubImage2D = cast(typeof(glTexSubImage2D))load("glTexSubImage2D");
	glUniform1f = cast(typeof(glUniform1f))load("glUniform1f");
	glUniform1fv = cast(typeof(glUniform1fv))load("glUniform1fv");
	glUniform1i = cast(typeof(glUniform1i))load("glUniform1i");
	glUniform1iv = cast(typeof(glUniform1iv))load("glUniform1iv");
	glUniform2f = cast(typeof(glUniform2f))load("glUniform2f");
	glUniform2fv = cast(typeof(glUniform2fv))load("glUniform2fv");
	glUniform2i = cast(typeof(glUniform2i))load("glUniform2i");
	glUniform2iv = cast(typeof(glUniform2iv))load("glUniform2iv");
	glUniform3f = cast(typeof(glUniform3f))load("glUniform3f");
	glUniform3fv = cast(typeof(glUniform3fv))load("glUniform3fv");
	glUniform3i = cast(typeof(glUniform3i))load("glUniform3i");
	glUniform3iv = cast(typeof(glUniform3iv))load("glUniform3iv");
	glUniform4f = cast(typeof(glUniform4f))load("glUniform4f");
	glUniform4fv = cast(typeof(glUniform4fv))load("glUniform4fv");
	glUniform4i = cast(typeof(glUniform4i))load("glUniform4i");
	glUniform4iv = cast(typeof(glUniform4iv))load("glUniform4iv");
	glUniformMatrix2fv = cast(typeof(glUniformMatrix2fv))load("glUniformMatrix2fv");
	glUniformMatrix3fv = cast(typeof(glUniformMatrix3fv))load("glUniformMatrix3fv");
	glUniformMatrix4fv = cast(typeof(glUniformMatrix4fv))load("glUniformMatrix4fv");
	glUseProgram = cast(typeof(glUseProgram))load("glUseProgram");
	glValidateProgram = cast(typeof(glValidateProgram))load("glValidateProgram");
	glVertexAttrib1f = cast(typeof(glVertexAttrib1f))load("glVertexAttrib1f");
	glVertexAttrib1fv = cast(typeof(glVertexAttrib1fv))load("glVertexAttrib1fv");
	glVertexAttrib2f = cast(typeof(glVertexAttrib2f))load("glVertexAttrib2f");
	glVertexAttrib2fv = cast(typeof(glVertexAttrib2fv))load("glVertexAttrib2fv");
	glVertexAttrib3f = cast(typeof(glVertexAttrib3f))load("glVertexAttrib3f");
	glVertexAttrib3fv = cast(typeof(glVertexAttrib3fv))load("glVertexAttrib3fv");
	glVertexAttrib4f = cast(typeof(glVertexAttrib4f))load("glVertexAttrib4f");
	glVertexAttrib4fv = cast(typeof(glVertexAttrib4fv))load("glVertexAttrib4fv");
	glVertexAttribPointer = cast(typeof(glVertexAttribPointer))load("glVertexAttribPointer");
	glViewport = cast(typeof(glViewport))load("glViewport");
	return;
}

void load_GL_QCOM_tiled_rendering(void* function(const(char)* name) load)
{
	if(!GL_QCOM_tiled_rendering) return;
	glStartTilingQCOM = cast(typeof(glStartTilingQCOM))load("glStartTilingQCOM");
	glEndTilingQCOM = cast(typeof(glEndTilingQCOM))load("glEndTilingQCOM");
	return;
}
void load_GL_NV_fence(void* function(const(char)* name) load)
{
	if(!GL_NV_fence) return;
	glDeleteFencesNV = cast(typeof(glDeleteFencesNV))load("glDeleteFencesNV");
	glGenFencesNV = cast(typeof(glGenFencesNV))load("glGenFencesNV");
	glIsFenceNV = cast(typeof(glIsFenceNV))load("glIsFenceNV");
	glTestFenceNV = cast(typeof(glTestFenceNV))load("glTestFenceNV");
	glGetFenceivNV = cast(typeof(glGetFenceivNV))load("glGetFenceivNV");
	glFinishFenceNV = cast(typeof(glFinishFenceNV))load("glFinishFenceNV");
	glSetFenceNV = cast(typeof(glSetFenceNV))load("glSetFenceNV");
	return;
}
void load_GL_ANGLE_translated_shader_source(void* function(const(char)* name) load)
{
	if(!GL_ANGLE_translated_shader_source) return;
	glGetTranslatedShaderSourceANGLE = cast(typeof(glGetTranslatedShaderSourceANGLE))load("glGetTranslatedShaderSourceANGLE");
	return;
}
void load_GL_EXT_robustness(void* function(const(char)* name) load)
{
	if(!GL_EXT_robustness) return;
	glGetGraphicsResetStatusEXT = cast(typeof(glGetGraphicsResetStatusEXT))load("glGetGraphicsResetStatusEXT");
	glReadnPixelsEXT = cast(typeof(glReadnPixelsEXT))load("glReadnPixelsEXT");
	glGetnUniformfvEXT = cast(typeof(glGetnUniformfvEXT))load("glGetnUniformfvEXT");
	glGetnUniformivEXT = cast(typeof(glGetnUniformivEXT))load("glGetnUniformivEXT");
	return;
}
void load_GL_NV_draw_instanced(void* function(const(char)* name) load)
{
	if(!GL_NV_draw_instanced) return;
	glDrawArraysInstancedNV = cast(typeof(glDrawArraysInstancedNV))load("glDrawArraysInstancedNV");
	glDrawElementsInstancedNV = cast(typeof(glDrawElementsInstancedNV))load("glDrawElementsInstancedNV");
	return;
}
void load_GL_NV_coverage_sample(void* function(const(char)* name) load)
{
	if(!GL_NV_coverage_sample) return;
	glCoverageMaskNV = cast(typeof(glCoverageMaskNV))load("glCoverageMaskNV");
	glCoverageOperationNV = cast(typeof(glCoverageOperationNV))load("glCoverageOperationNV");
	return;
}
void load_GL_EXT_disjoint_timer_query(void* function(const(char)* name) load)
{
	if(!GL_EXT_disjoint_timer_query) return;
	glGenQueriesEXT = cast(typeof(glGenQueriesEXT))load("glGenQueriesEXT");
	glDeleteQueriesEXT = cast(typeof(glDeleteQueriesEXT))load("glDeleteQueriesEXT");
	glIsQueryEXT = cast(typeof(glIsQueryEXT))load("glIsQueryEXT");
	glBeginQueryEXT = cast(typeof(glBeginQueryEXT))load("glBeginQueryEXT");
	glEndQueryEXT = cast(typeof(glEndQueryEXT))load("glEndQueryEXT");
	glQueryCounterEXT = cast(typeof(glQueryCounterEXT))load("glQueryCounterEXT");
	glGetQueryivEXT = cast(typeof(glGetQueryivEXT))load("glGetQueryivEXT");
	glGetQueryObjectivEXT = cast(typeof(glGetQueryObjectivEXT))load("glGetQueryObjectivEXT");
	glGetQueryObjectuivEXT = cast(typeof(glGetQueryObjectuivEXT))load("glGetQueryObjectuivEXT");
	glGetQueryObjecti64vEXT = cast(typeof(glGetQueryObjecti64vEXT))load("glGetQueryObjecti64vEXT");
	glGetQueryObjectui64vEXT = cast(typeof(glGetQueryObjectui64vEXT))load("glGetQueryObjectui64vEXT");
	return;
}
void load_GL_EXT_multi_draw_arrays(void* function(const(char)* name) load)
{
	if(!GL_EXT_multi_draw_arrays) return;
	glMultiDrawArraysEXT = cast(typeof(glMultiDrawArraysEXT))load("glMultiDrawArraysEXT");
	glMultiDrawElementsEXT = cast(typeof(glMultiDrawElementsEXT))load("glMultiDrawElementsEXT");
	return;
}
void load_GL_QCOM_driver_control(void* function(const(char)* name) load)
{
	if(!GL_QCOM_driver_control) return;
	glGetDriverControlsQCOM = cast(typeof(glGetDriverControlsQCOM))load("glGetDriverControlsQCOM");
	glGetDriverControlStringQCOM = cast(typeof(glGetDriverControlStringQCOM))load("glGetDriverControlStringQCOM");
	glEnableDriverControlQCOM = cast(typeof(glEnableDriverControlQCOM))load("glEnableDriverControlQCOM");
	glDisableDriverControlQCOM = cast(typeof(glDisableDriverControlQCOM))load("glDisableDriverControlQCOM");
	return;
}
void load_GL_EXT_debug_marker(void* function(const(char)* name) load)
{
	if(!GL_EXT_debug_marker) return;
	glInsertEventMarkerEXT = cast(typeof(glInsertEventMarkerEXT))load("glInsertEventMarkerEXT");
	glPushGroupMarkerEXT = cast(typeof(glPushGroupMarkerEXT))load("glPushGroupMarkerEXT");
	glPopGroupMarkerEXT = cast(typeof(glPopGroupMarkerEXT))load("glPopGroupMarkerEXT");
	return;
}
void load_GL_EXT_multisampled_render_to_texture(void* function(const(char)* name) load)
{
	if(!GL_EXT_multisampled_render_to_texture) return;
	glRenderbufferStorageMultisampleEXT = cast(typeof(glRenderbufferStorageMultisampleEXT))load("glRenderbufferStorageMultisampleEXT");
	glFramebufferTexture2DMultisampleEXT = cast(typeof(glFramebufferTexture2DMultisampleEXT))load("glFramebufferTexture2DMultisampleEXT");
	return;
}
void load_GL_ANGLE_framebuffer_multisample(void* function(const(char)* name) load)
{
	if(!GL_ANGLE_framebuffer_multisample) return;
	glRenderbufferStorageMultisampleANGLE = cast(typeof(glRenderbufferStorageMultisampleANGLE))load("glRenderbufferStorageMultisampleANGLE");
	return;
}
void load_GL_OES_get_program_binary(void* function(const(char)* name) load)
{
	if(!GL_OES_get_program_binary) return;
	glGetProgramBinaryOES = cast(typeof(glGetProgramBinaryOES))load("glGetProgramBinaryOES");
	glProgramBinaryOES = cast(typeof(glProgramBinaryOES))load("glProgramBinaryOES");
	return;
}
void load_GL_APPLE_framebuffer_multisample(void* function(const(char)* name) load)
{
	if(!GL_APPLE_framebuffer_multisample) return;
	glRenderbufferStorageMultisampleAPPLE = cast(typeof(glRenderbufferStorageMultisampleAPPLE))load("glRenderbufferStorageMultisampleAPPLE");
	glResolveMultisampleFramebufferAPPLE = cast(typeof(glResolveMultisampleFramebufferAPPLE))load("glResolveMultisampleFramebufferAPPLE");
	return;
}
void load_GL_NV_framebuffer_blit(void* function(const(char)* name) load)
{
	if(!GL_NV_framebuffer_blit) return;
	glBlitFramebufferNV = cast(typeof(glBlitFramebufferNV))load("glBlitFramebufferNV");
	return;
}
void load_GL_QCOM_alpha_test(void* function(const(char)* name) load)
{
	if(!GL_QCOM_alpha_test) return;
	glAlphaFuncQCOM = cast(typeof(glAlphaFuncQCOM))load("glAlphaFuncQCOM");
	return;
}
void load_GL_KHR_debug(void* function(const(char)* name) load)
{
	if(!GL_KHR_debug) return;
	glDebugMessageControl = cast(typeof(glDebugMessageControl))load("glDebugMessageControl");
	glDebugMessageInsert = cast(typeof(glDebugMessageInsert))load("glDebugMessageInsert");
	glDebugMessageCallback = cast(typeof(glDebugMessageCallback))load("glDebugMessageCallback");
	glGetDebugMessageLog = cast(typeof(glGetDebugMessageLog))load("glGetDebugMessageLog");
	glPushDebugGroup = cast(typeof(glPushDebugGroup))load("glPushDebugGroup");
	glPopDebugGroup = cast(typeof(glPopDebugGroup))load("glPopDebugGroup");
	glObjectLabel = cast(typeof(glObjectLabel))load("glObjectLabel");
	glGetObjectLabel = cast(typeof(glGetObjectLabel))load("glGetObjectLabel");
	glObjectPtrLabel = cast(typeof(glObjectPtrLabel))load("glObjectPtrLabel");
	glGetObjectPtrLabel = cast(typeof(glGetObjectPtrLabel))load("glGetObjectPtrLabel");
	glGetPointerv = cast(typeof(glGetPointerv))load("glGetPointerv");
	glDebugMessageControlKHR = cast(typeof(glDebugMessageControlKHR))load("glDebugMessageControlKHR");
	glDebugMessageInsertKHR = cast(typeof(glDebugMessageInsertKHR))load("glDebugMessageInsertKHR");
	glDebugMessageCallbackKHR = cast(typeof(glDebugMessageCallbackKHR))load("glDebugMessageCallbackKHR");
	glGetDebugMessageLogKHR = cast(typeof(glGetDebugMessageLogKHR))load("glGetDebugMessageLogKHR");
	glPushDebugGroupKHR = cast(typeof(glPushDebugGroupKHR))load("glPushDebugGroupKHR");
	glPopDebugGroupKHR = cast(typeof(glPopDebugGroupKHR))load("glPopDebugGroupKHR");
	glObjectLabelKHR = cast(typeof(glObjectLabelKHR))load("glObjectLabelKHR");
	glGetObjectLabelKHR = cast(typeof(glGetObjectLabelKHR))load("glGetObjectLabelKHR");
	glObjectPtrLabelKHR = cast(typeof(glObjectPtrLabelKHR))load("glObjectPtrLabelKHR");
	glGetObjectPtrLabelKHR = cast(typeof(glGetObjectPtrLabelKHR))load("glGetObjectPtrLabelKHR");
	glGetPointervKHR = cast(typeof(glGetPointervKHR))load("glGetPointervKHR");
	return;
}
void load_GL_EXT_occlusion_query_boolean(void* function(const(char)* name) load)
{
	if(!GL_EXT_occlusion_query_boolean) return;
	glGenQueriesEXT = cast(typeof(glGenQueriesEXT))load("glGenQueriesEXT");
	glDeleteQueriesEXT = cast(typeof(glDeleteQueriesEXT))load("glDeleteQueriesEXT");
	glIsQueryEXT = cast(typeof(glIsQueryEXT))load("glIsQueryEXT");
	glBeginQueryEXT = cast(typeof(glBeginQueryEXT))load("glBeginQueryEXT");
	glEndQueryEXT = cast(typeof(glEndQueryEXT))load("glEndQueryEXT");
	glGetQueryivEXT = cast(typeof(glGetQueryivEXT))load("glGetQueryivEXT");
	glGetQueryObjectuivEXT = cast(typeof(glGetQueryObjectuivEXT))load("glGetQueryObjectuivEXT");
	return;
}
void load_GL_APPLE_sync(void* function(const(char)* name) load)
{
	if(!GL_APPLE_sync) return;
	glFenceSyncAPPLE = cast(typeof(glFenceSyncAPPLE))load("glFenceSyncAPPLE");
	glIsSyncAPPLE = cast(typeof(glIsSyncAPPLE))load("glIsSyncAPPLE");
	glDeleteSyncAPPLE = cast(typeof(glDeleteSyncAPPLE))load("glDeleteSyncAPPLE");
	glClientWaitSyncAPPLE = cast(typeof(glClientWaitSyncAPPLE))load("glClientWaitSyncAPPLE");
	glWaitSyncAPPLE = cast(typeof(glWaitSyncAPPLE))load("glWaitSyncAPPLE");
	glGetInteger64vAPPLE = cast(typeof(glGetInteger64vAPPLE))load("glGetInteger64vAPPLE");
	glGetSyncivAPPLE = cast(typeof(glGetSyncivAPPLE))load("glGetSyncivAPPLE");
	return;
}
void load_GL_QCOM_extended_get2(void* function(const(char)* name) load)
{
	if(!GL_QCOM_extended_get2) return;
	glExtGetShadersQCOM = cast(typeof(glExtGetShadersQCOM))load("glExtGetShadersQCOM");
	glExtGetProgramsQCOM = cast(typeof(glExtGetProgramsQCOM))load("glExtGetProgramsQCOM");
	glExtIsProgramBinaryQCOM = cast(typeof(glExtIsProgramBinaryQCOM))load("glExtIsProgramBinaryQCOM");
	glExtGetProgramBinarySourceQCOM = cast(typeof(glExtGetProgramBinarySourceQCOM))load("glExtGetProgramBinarySourceQCOM");
	return;
}
void load_GL_EXT_separate_shader_objects(void* function(const(char)* name) load)
{
	if(!GL_EXT_separate_shader_objects) return;
	glUseShaderProgramEXT = cast(typeof(glUseShaderProgramEXT))load("glUseShaderProgramEXT");
	glActiveProgramEXT = cast(typeof(glActiveProgramEXT))load("glActiveProgramEXT");
	glCreateShaderProgramEXT = cast(typeof(glCreateShaderProgramEXT))load("glCreateShaderProgramEXT");
	glActiveShaderProgramEXT = cast(typeof(glActiveShaderProgramEXT))load("glActiveShaderProgramEXT");
	glBindProgramPipelineEXT = cast(typeof(glBindProgramPipelineEXT))load("glBindProgramPipelineEXT");
	glCreateShaderProgramvEXT = cast(typeof(glCreateShaderProgramvEXT))load("glCreateShaderProgramvEXT");
	glDeleteProgramPipelinesEXT = cast(typeof(glDeleteProgramPipelinesEXT))load("glDeleteProgramPipelinesEXT");
	glGenProgramPipelinesEXT = cast(typeof(glGenProgramPipelinesEXT))load("glGenProgramPipelinesEXT");
	glGetProgramPipelineInfoLogEXT = cast(typeof(glGetProgramPipelineInfoLogEXT))load("glGetProgramPipelineInfoLogEXT");
	glGetProgramPipelineivEXT = cast(typeof(glGetProgramPipelineivEXT))load("glGetProgramPipelineivEXT");
	glIsProgramPipelineEXT = cast(typeof(glIsProgramPipelineEXT))load("glIsProgramPipelineEXT");
	glProgramParameteriEXT = cast(typeof(glProgramParameteriEXT))load("glProgramParameteriEXT");
	glProgramUniform1fEXT = cast(typeof(glProgramUniform1fEXT))load("glProgramUniform1fEXT");
	glProgramUniform1fvEXT = cast(typeof(glProgramUniform1fvEXT))load("glProgramUniform1fvEXT");
	glProgramUniform1iEXT = cast(typeof(glProgramUniform1iEXT))load("glProgramUniform1iEXT");
	glProgramUniform1ivEXT = cast(typeof(glProgramUniform1ivEXT))load("glProgramUniform1ivEXT");
	glProgramUniform2fEXT = cast(typeof(glProgramUniform2fEXT))load("glProgramUniform2fEXT");
	glProgramUniform2fvEXT = cast(typeof(glProgramUniform2fvEXT))load("glProgramUniform2fvEXT");
	glProgramUniform2iEXT = cast(typeof(glProgramUniform2iEXT))load("glProgramUniform2iEXT");
	glProgramUniform2ivEXT = cast(typeof(glProgramUniform2ivEXT))load("glProgramUniform2ivEXT");
	glProgramUniform3fEXT = cast(typeof(glProgramUniform3fEXT))load("glProgramUniform3fEXT");
	glProgramUniform3fvEXT = cast(typeof(glProgramUniform3fvEXT))load("glProgramUniform3fvEXT");
	glProgramUniform3iEXT = cast(typeof(glProgramUniform3iEXT))load("glProgramUniform3iEXT");
	glProgramUniform3ivEXT = cast(typeof(glProgramUniform3ivEXT))load("glProgramUniform3ivEXT");
	glProgramUniform4fEXT = cast(typeof(glProgramUniform4fEXT))load("glProgramUniform4fEXT");
	glProgramUniform4fvEXT = cast(typeof(glProgramUniform4fvEXT))load("glProgramUniform4fvEXT");
	glProgramUniform4iEXT = cast(typeof(glProgramUniform4iEXT))load("glProgramUniform4iEXT");
	glProgramUniform4ivEXT = cast(typeof(glProgramUniform4ivEXT))load("glProgramUniform4ivEXT");
	glProgramUniformMatrix2fvEXT = cast(typeof(glProgramUniformMatrix2fvEXT))load("glProgramUniformMatrix2fvEXT");
	glProgramUniformMatrix3fvEXT = cast(typeof(glProgramUniformMatrix3fvEXT))load("glProgramUniformMatrix3fvEXT");
	glProgramUniformMatrix4fvEXT = cast(typeof(glProgramUniformMatrix4fvEXT))load("glProgramUniformMatrix4fvEXT");
	glUseProgramStagesEXT = cast(typeof(glUseProgramStagesEXT))load("glUseProgramStagesEXT");
	glValidateProgramPipelineEXT = cast(typeof(glValidateProgramPipelineEXT))load("glValidateProgramPipelineEXT");
	return;
}
void load_GL_NV_framebuffer_multisample(void* function(const(char)* name) load)
{
	if(!GL_NV_framebuffer_multisample) return;
	glRenderbufferStorageMultisampleNV = cast(typeof(glRenderbufferStorageMultisampleNV))load("glRenderbufferStorageMultisampleNV");
	return;
}
void load_GL_NV_draw_buffers(void* function(const(char)* name) load)
{
	if(!GL_NV_draw_buffers) return;
	glDrawBuffersNV = cast(typeof(glDrawBuffersNV))load("glDrawBuffersNV");
	return;
}
void load_GL_EXT_draw_buffers(void* function(const(char)* name) load)
{
	if(!GL_EXT_draw_buffers) return;
	glDrawBuffersEXT = cast(typeof(glDrawBuffersEXT))load("glDrawBuffersEXT");
	return;
}
void load_GL_EXT_debug_label(void* function(const(char)* name) load)
{
	if(!GL_EXT_debug_label) return;
	glLabelObjectEXT = cast(typeof(glLabelObjectEXT))load("glLabelObjectEXT");
	glGetObjectLabelEXT = cast(typeof(glGetObjectLabelEXT))load("glGetObjectLabelEXT");
	return;
}
void load_GL_OES_EGL_image(void* function(const(char)* name) load)
{
	if(!GL_OES_EGL_image) return;
	glEGLImageTargetTexture2DOES = cast(typeof(glEGLImageTargetTexture2DOES))load("glEGLImageTargetTexture2DOES");
	glEGLImageTargetRenderbufferStorageOES = cast(typeof(glEGLImageTargetRenderbufferStorageOES))load("glEGLImageTargetRenderbufferStorageOES");
	return;
}
void load_GL_EXT_blend_minmax(void* function(const(char)* name) load)
{
	if(!GL_EXT_blend_minmax) return;
	glBlendEquationEXT = cast(typeof(glBlendEquationEXT))load("glBlendEquationEXT");
	return;
}
void load_GL_EXT_texture_storage(void* function(const(char)* name) load)
{
	if(!GL_EXT_texture_storage) return;
	glTexStorage1DEXT = cast(typeof(glTexStorage1DEXT))load("glTexStorage1DEXT");
	glTexStorage2DEXT = cast(typeof(glTexStorage2DEXT))load("glTexStorage2DEXT");
	glTexStorage3DEXT = cast(typeof(glTexStorage3DEXT))load("glTexStorage3DEXT");
	glTextureStorage1DEXT = cast(typeof(glTextureStorage1DEXT))load("glTextureStorage1DEXT");
	glTextureStorage2DEXT = cast(typeof(glTextureStorage2DEXT))load("glTextureStorage2DEXT");
	glTextureStorage3DEXT = cast(typeof(glTextureStorage3DEXT))load("glTextureStorage3DEXT");
	return;
}
void load_GL_EXT_map_buffer_range(void* function(const(char)* name) load)
{
	if(!GL_EXT_map_buffer_range) return;
	glMapBufferRangeEXT = cast(typeof(glMapBufferRangeEXT))load("glMapBufferRangeEXT");
	glFlushMappedBufferRangeEXT = cast(typeof(glFlushMappedBufferRangeEXT))load("glFlushMappedBufferRangeEXT");
	return;
}
void load_GL_OES_mapbuffer(void* function(const(char)* name) load)
{
	if(!GL_OES_mapbuffer) return;
	glMapBufferOES = cast(typeof(glMapBufferOES))load("glMapBufferOES");
	glUnmapBufferOES = cast(typeof(glUnmapBufferOES))load("glUnmapBufferOES");
	glGetBufferPointervOES = cast(typeof(glGetBufferPointervOES))load("glGetBufferPointervOES");
	return;
}
void load_GL_AMD_performance_monitor(void* function(const(char)* name) load)
{
	if(!GL_AMD_performance_monitor) return;
	glGetPerfMonitorGroupsAMD = cast(typeof(glGetPerfMonitorGroupsAMD))load("glGetPerfMonitorGroupsAMD");
	glGetPerfMonitorCountersAMD = cast(typeof(glGetPerfMonitorCountersAMD))load("glGetPerfMonitorCountersAMD");
	glGetPerfMonitorGroupStringAMD = cast(typeof(glGetPerfMonitorGroupStringAMD))load("glGetPerfMonitorGroupStringAMD");
	glGetPerfMonitorCounterStringAMD = cast(typeof(glGetPerfMonitorCounterStringAMD))load("glGetPerfMonitorCounterStringAMD");
	glGetPerfMonitorCounterInfoAMD = cast(typeof(glGetPerfMonitorCounterInfoAMD))load("glGetPerfMonitorCounterInfoAMD");
	glGenPerfMonitorsAMD = cast(typeof(glGenPerfMonitorsAMD))load("glGenPerfMonitorsAMD");
	glDeletePerfMonitorsAMD = cast(typeof(glDeletePerfMonitorsAMD))load("glDeletePerfMonitorsAMD");
	glSelectPerfMonitorCountersAMD = cast(typeof(glSelectPerfMonitorCountersAMD))load("glSelectPerfMonitorCountersAMD");
	glBeginPerfMonitorAMD = cast(typeof(glBeginPerfMonitorAMD))load("glBeginPerfMonitorAMD");
	glEndPerfMonitorAMD = cast(typeof(glEndPerfMonitorAMD))load("glEndPerfMonitorAMD");
	glGetPerfMonitorCounterDataAMD = cast(typeof(glGetPerfMonitorCounterDataAMD))load("glGetPerfMonitorCounterDataAMD");
	return;
}
void load_GL_IMG_multisampled_render_to_texture(void* function(const(char)* name) load)
{
	if(!GL_IMG_multisampled_render_to_texture) return;
	glRenderbufferStorageMultisampleIMG = cast(typeof(glRenderbufferStorageMultisampleIMG))load("glRenderbufferStorageMultisampleIMG");
	glFramebufferTexture2DMultisampleIMG = cast(typeof(glFramebufferTexture2DMultisampleIMG))load("glFramebufferTexture2DMultisampleIMG");
	return;
}
void load_GL_APPLE_copy_texture_levels(void* function(const(char)* name) load)
{
	if(!GL_APPLE_copy_texture_levels) return;
	glCopyTextureLevelsAPPLE = cast(typeof(glCopyTextureLevelsAPPLE))load("glCopyTextureLevelsAPPLE");
	return;
}
void load_GL_EXT_multiview_draw_buffers(void* function(const(char)* name) load)
{
	if(!GL_EXT_multiview_draw_buffers) return;
	glReadBufferIndexedEXT = cast(typeof(glReadBufferIndexedEXT))load("glReadBufferIndexedEXT");
	glDrawBuffersIndexedEXT = cast(typeof(glDrawBuffersIndexedEXT))load("glDrawBuffersIndexedEXT");
	glGetIntegeri_vEXT = cast(typeof(glGetIntegeri_vEXT))load("glGetIntegeri_vEXT");
	return;
}
void load_GL_QCOM_extended_get(void* function(const(char)* name) load)
{
	if(!GL_QCOM_extended_get) return;
	glExtGetTexturesQCOM = cast(typeof(glExtGetTexturesQCOM))load("glExtGetTexturesQCOM");
	glExtGetBuffersQCOM = cast(typeof(glExtGetBuffersQCOM))load("glExtGetBuffersQCOM");
	glExtGetRenderbuffersQCOM = cast(typeof(glExtGetRenderbuffersQCOM))load("glExtGetRenderbuffersQCOM");
	glExtGetFramebuffersQCOM = cast(typeof(glExtGetFramebuffersQCOM))load("glExtGetFramebuffersQCOM");
	glExtGetTexLevelParameterivQCOM = cast(typeof(glExtGetTexLevelParameterivQCOM))load("glExtGetTexLevelParameterivQCOM");
	glExtTexObjectStateOverrideiQCOM = cast(typeof(glExtTexObjectStateOverrideiQCOM))load("glExtTexObjectStateOverrideiQCOM");
	glExtGetTexSubImageQCOM = cast(typeof(glExtGetTexSubImageQCOM))load("glExtGetTexSubImageQCOM");
	glExtGetBufferPointervQCOM = cast(typeof(glExtGetBufferPointervQCOM))load("glExtGetBufferPointervQCOM");
	return;
}
void load_GL_ANGLE_framebuffer_blit(void* function(const(char)* name) load)
{
	if(!GL_ANGLE_framebuffer_blit) return;
	glBlitFramebufferANGLE = cast(typeof(glBlitFramebufferANGLE))load("glBlitFramebufferANGLE");
	return;
}
void load_GL_OES_texture_3D(void* function(const(char)* name) load)
{
	if(!GL_OES_texture_3D) return;
	glTexImage3DOES = cast(typeof(glTexImage3DOES))load("glTexImage3DOES");
	glTexSubImage3DOES = cast(typeof(glTexSubImage3DOES))load("glTexSubImage3DOES");
	glCopyTexSubImage3DOES = cast(typeof(glCopyTexSubImage3DOES))load("glCopyTexSubImage3DOES");
	glCompressedTexImage3DOES = cast(typeof(glCompressedTexImage3DOES))load("glCompressedTexImage3DOES");
	glCompressedTexSubImage3DOES = cast(typeof(glCompressedTexSubImage3DOES))load("glCompressedTexSubImage3DOES");
	glFramebufferTexture3DOES = cast(typeof(glFramebufferTexture3DOES))load("glFramebufferTexture3DOES");
	return;
}
void load_GL_NV_read_buffer(void* function(const(char)* name) load)
{
	if(!GL_NV_read_buffer) return;
	glReadBufferNV = cast(typeof(glReadBufferNV))load("glReadBufferNV");
	return;
}
void load_GL_NV_instanced_arrays(void* function(const(char)* name) load)
{
	if(!GL_NV_instanced_arrays) return;
	glVertexAttribDivisorNV = cast(typeof(glVertexAttribDivisorNV))load("glVertexAttribDivisorNV");
	return;
}
void load_GL_ANGLE_instanced_arrays(void* function(const(char)* name) load)
{
	if(!GL_ANGLE_instanced_arrays) return;
	glDrawArraysInstancedANGLE = cast(typeof(glDrawArraysInstancedANGLE))load("glDrawArraysInstancedANGLE");
	glDrawElementsInstancedANGLE = cast(typeof(glDrawElementsInstancedANGLE))load("glDrawElementsInstancedANGLE");
	glVertexAttribDivisorANGLE = cast(typeof(glVertexAttribDivisorANGLE))load("glVertexAttribDivisorANGLE");
	return;
}
void load_GL_EXT_discard_framebuffer(void* function(const(char)* name) load)
{
	if(!GL_EXT_discard_framebuffer) return;
	glDiscardFramebufferEXT = cast(typeof(glDiscardFramebufferEXT))load("glDiscardFramebufferEXT");
	return;
}
void load_GL_OES_vertex_array_object(void* function(const(char)* name) load)
{
	if(!GL_OES_vertex_array_object) return;
	glBindVertexArrayOES = cast(typeof(glBindVertexArrayOES))load("glBindVertexArrayOES");
	glDeleteVertexArraysOES = cast(typeof(glDeleteVertexArraysOES))load("glDeleteVertexArraysOES");
	glGenVertexArraysOES = cast(typeof(glGenVertexArraysOES))load("glGenVertexArraysOES");
	glIsVertexArrayOES = cast(typeof(glIsVertexArrayOES))load("glIsVertexArrayOES");
	return;
}
