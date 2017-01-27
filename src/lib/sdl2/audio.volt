/*
  Simple DirectMedia Layer
  Copyright (C) 1997-2013 Sam Lantinga <slouken@libsdl.org>

  This software is provided 'as-is', without any express or implied
  warranty.  In no event will the authors be held liable for any damages
  arising from the use of this software.

  Permission is granted to anyone to use this software for any purpose,
  including commercial applications, and to alter it and redistribute it
  freely, subject to the following restrictions:

  1. The origin of this software must not be misrepresented; you must not
     claim that you wrote the original software. If you use this software
     in a product, an acknowledgment in the product documentation would be
     appreciated but is not required.
  2. Altered source versions must be plainly marked as such, and must not be
     misrepresented as being the original software.
  3. This notice may not be removed or altered from any source distribution.
*/
module lib.sdl2.audio;
extern (C):
version (!Windows):

/*
 *  \file SDL_audio.h
 *
 *  Access to the raw audio mixing buffer for the SDL library.
 */


import lib.sdl2.stdinc;
import lib.sdl2.error;
import lib.sdl2.mutex;
import lib.sdl2.thread;
import lib.sdl2.rwops;

/**
 *  \brief Audio format flags.
 *
 *  These are what the 16 bits in SDL_AudioFormat currently mean...
 *  (Unspecified bits are always zero).
 *
 *  \verbatim
    ++-----------------------sample is signed if set
    ||
    ||       ++-----------sample is bigendian if set
    ||       ||
    ||       ||          ++---sample is float if set
    ||       ||          ||
    ||       ||          || +---sample bit size---+
    ||       ||          || |                     |
    15 14 13 12 11 10 09 08 07 06 05 04 03 02 01 00
    \endverbatim
 *
 *  There are macros in SDL 2.0 and later to query these bits.
 */
alias SDL_AudioFormat = Uint16;

/**
 *  \name Audio flags
 */
/* */

enum SDL_AUDIO_MASK_BITSIZE = (0xFF);
enum SDL_AUDIO_MASK_DATATYPE = (1<<8);
enum SDL_AUDIO_MASK_ENDIAN = (1<<12);
enum SDL_AUDIO_MASK_SIGNED = (1<<15);
int SDL_AUDIO_BITSIZE(int x) { return x & SDL_AUDIO_MASK_BITSIZE; }
bool SDL_AUDIO_ISFLOAT(int x) { return (x & SDL_AUDIO_MASK_DATATYPE) != 0; }
bool SDL_AUDIO_ISBIGENDIAN(int x) { return (x & SDL_AUDIO_MASK_ENDIAN) != 0; }
bool SDL_AUDIO_ISSIGNED(int x) { return (x & SDL_AUDIO_MASK_SIGNED) != 0; }
bool SDL_AUDIO_ISINT(int x) { return !SDL_AUDIO_ISFLOAT(x); }
bool SDL_AUDIO_ISLITTLEENDIAN(int x) { return !SDL_AUDIO_ISBIGENDIAN(x); }
bool SDL_AUDIO_ISUNSIGNED(int x) { return !SDL_AUDIO_ISSIGNED(x); }

/**
 *  \name Audio format flags
 *
 *  Defaults to LSB byte order.
 */
/* */
enum AUDIO_U8 = 0x0008  /*< Unsigned 8-bit samples */;
enum AUDIO_S8 = 0x8008  /*< Signed 8-bit samples */;
enum AUDIO_U16LSB = 0x0010  /*< Unsigned 16-bit samples */;
enum AUDIO_S16LSB = 0x8010  /*< Signed 16-bit samples */;
enum AUDIO_U16MSB = 0x1010  /*< As above, but big-endian byte order */;
enum AUDIO_S16MSB = 0x9010  /*< As above, but big-endian byte order */;
enum AUDIO_U16 = AUDIO_U16LSB;
enum AUDIO_S16 = AUDIO_S16LSB;
/* */

/**
 *  \name int32 support
 */
/* */
enum AUDIO_S32LSB = 0x8020  /*< 32-bit integer samples */;
enum AUDIO_S32MSB = 0x9020  /*< As above, but big-endian byte order */;
enum AUDIO_S32 = AUDIO_S32LSB;
/* */

/**
 *  \name float32 support
 */
/* */
enum AUDIO_F32LSB = 0x8120  /*< 32-bit floating point samples */;
enum AUDIO_F32MSB = 0x9120  /*< As above, but big-endian byte order */;
enum AUDIO_F32 = AUDIO_F32LSB;
/* */

/**
 *  \name Native audio byte ordering
 */
/* */
version (LittleEndian) {
enum AUDIO_U16SYS = AUDIO_U16LSB;
enum AUDIO_S16SYS = AUDIO_S16LSB;
enum AUDIO_S32SYS = AUDIO_S32LSB;
enum AUDIO_F32SYS = AUDIO_F32LSB;
} else {
enum AUDIO_U16SYS = AUDIO_U16MSB;
enum AUDIO_S16SYS = AUDIO_S16MSB;
enum AUDIO_S32SYS = AUDIO_S32MSB;
enum AUDIO_F32SYS = AUDIO_F32MSB;
}
/* */

/**
 *  \name Allow change flags
 *
 *  Which audio format changes are allowed when opening a device.
 */
/* */
enum SDL_AUDIO_ALLOW_FREQUENCY_CHANGE = 0x00000001;
enum SDL_AUDIO_ALLOW_FORMAT_CHANGE = 0x00000002;
enum SDL_AUDIO_ALLOW_CHANNELS_CHANGE = 0x00000004;
enum SDL_AUDIO_ALLOW_ANY_CHANGE = (SDL_AUDIO_ALLOW_FREQUENCY_CHANGE|SDL_AUDIO_ALLOW_FORMAT_CHANGE|SDL_AUDIO_ALLOW_CHANNELS_CHANGE);
/* */

/* *//*Audio flags*/

/**
 *  This function is called when the audio device needs more data.
 *
 *  \param userdata An application-specific parameter saved in
 *                  the SDL_AudioSpec structure
 *  \param stream A pointer to the audio data buffer.
 *  \param len    The length of that buffer in bytes.
 *
 *  Once the callback returns, the buffer will no longer be valid.
 *  Stereo samples are stored in a LRLRLR ordering.
 */
alias SDL_AudioCallback = void function(void *userdata, Uint8 * stream,
                                            int len);

/**
 *  The calculated values in this structure are calculated by SDL_OpenAudio().
 */
struct SDL_AudioSpec
{
    int freq;                   /**< DSP frequency -- samples per second */
    SDL_AudioFormat format;     /**< Audio data format */
    Uint8 channels;             /**< Number of channels: 1 mono, 2 stereo */
    Uint8 silence;              /**< Audio buffer silence value (calculated) */
    Uint16 samples;             /**< Audio buffer size in samples (power of 2) */
    Uint16 padding;             /**< Necessary for some compile environments */
    Uint32 size;                /**< Audio buffer size in bytes (calculated) */
    SDL_AudioCallback callback;
    void *userdata;
}

alias SDL_AudioFilter = void function(void * cvt,
                                          SDL_AudioFormat format);

/**
 *  A structure to hold a set of audio conversion filters and buffers.
 */
struct SDL_AudioCVT
{
    int needed;                 //< Set to 1 if conversion possible */
    SDL_AudioFormat src_format; //< Source audio format */
    SDL_AudioFormat dst_format; //< Target audio format */
    double rate_incr;           //< Rate conversion increment */
    Uint8 *buf;                 //< Buffer to hold entire audio data */
    int len;                    //< Length of original audio buffer */
    int len_cvt;                //< Length of converted audio buffer */
    int len_mult;               //< buffer must be len*len_mult big */
    double len_ratio;           //< Given len, final size is len*len_ratio */
    SDL_AudioFilter[10] filters;       //< Filter list */
    int filter_index;           //< Current audio conversion function */
}


/* Function prototypes */

/**
 *  \name Driver discovery functions
 *
 *  These functions return the list of built in audio drivers, in the
 *  order that they are normally initialized by default.
 */
/* */
int  SDL_GetNumAudioDrivers();
const char * SDL_GetAudioDriver(int index);
/* */

/**
 *  \name Initialization and cleanup
 *
 *  \internal These functions are used internally, and should not be used unless
 *            you have a specific need to specify the audio driver you want to
 *            use.  You should normally use SDL_Init() or SDL_InitSubSystem().
 */
/* */
int  SDL_AudioInit(const char *driver_name);
void  SDL_AudioQuit();
/* */

/**
 *  This function returns the name of the current audio driver, or NULL
 *  if no driver has been initialized.
 */
const char * SDL_GetCurrentAudioDriver();

/**
 *  This function opens the audio device with the desired parameters, and
 *  returns 0 if successful, placing the actual hardware parameters in the
 *  structure pointed to by \c obtained.  If \c obtained is NULL, the audio
 *  data passed to the callback function will be guaranteed to be in the
 *  requested format, and will be automatically converted to the hardware
 *  audio format if necessary.  This function returns -1 if it failed
 *  to open the audio device, or couldn't set up the audio thread.
 *
 *  When filling in the desired audio spec structure,
 *    - \c desired->freq should be the desired audio frequency in samples-per-
 *      second.
 *    - \c desired->format should be the desired audio format.
 *    - \c desired->samples is the desired size of the audio buffer, in
 *      samples.  This number should be a power of two, and may be adjusted by
 *      the audio driver to a value more suitable for the hardware.  Good values
 *      seem to range between 512 and 8096 inclusive, depending on the
 *      application and CPU speed.  Smaller values yield faster response time,
 *      but can lead to underflow if the application is doing heavy processing
 *      and cannot fill the audio buffer in time.  A stereo sample consists of
 *      both right and left channels in LR ordering.
 *      Note that the number of samples is directly related to time by the
 *      following formula:  \code ms = (samples*1000)/freq \endcode
 *    - \c desired->size is the size in bytes of the audio buffer, and is
 *      calculated by SDL_OpenAudio().
 *    - \c desired->silence is the value used to set the buffer to silence,
 *      and is calculated by SDL_OpenAudio().
 *    - \c desired->callback should be set to a function that will be called
 *      when the audio device is ready for more data.  It is passed a pointer
 *      to the audio buffer, and the length in bytes of the audio buffer.
 *      This function usually runs in a separate thread, and so you should
 *      protect data structures that it accesses by calling SDL_LockAudio()
 *      and SDL_UnlockAudio() in your code.
 *    - \c desired->userdata is passed as the first parameter to your callback
 *      function.
 *
 *  The audio device starts out playing silence when it's opened, and should
 *  be enabled for playing by calling \c SDL_PauseAudio(0) when you are ready
 *  for your audio callback function to be called.  Since the audio driver
 *  may modify the requested size of the audio buffer, you should allocate
 *  any local mixing buffers after you open the audio device.
 */
int  SDL_OpenAudio(SDL_AudioSpec * desired,
                                          SDL_AudioSpec * obtained);

/**
 *  SDL Audio Device IDs.
 *
 *  A successful call to SDL_OpenAudio() is always device id 1, and legacy
 *  SDL audio APIs assume you want this device ID. SDL_OpenAudioDevice() calls
 *  always returns devices >= 2 on success. The legacy calls are good both
 *  for backwards compatibility and when you don't care about multiple,
 *  specific, or capture devices.
 */
alias SDL_AudioDeviceID = Uint32;

/**
 *  Get the number of available devices exposed by the current driver.
 *  Only valid after a successfully initializing the audio subsystem.
 *  Returns -1 if an explicit list of devices can't be determined; this is
 *  not an error. For example, if SDL is set up to talk to a remote audio
 *  server, it can't list every one available on the Internet, but it will
 *  still allow a specific host to be specified to SDL_OpenAudioDevice().
 *
 *  In many common cases, when this function returns a value <= 0, it can still
 *  successfully open the default device (NULL for first argument of
 *  SDL_OpenAudioDevice()).
 */
int  SDL_GetNumAudioDevices(int iscapture);

/**
 *  Get the human-readable name of a specific audio device.
 *  Must be a value between 0 and (number of audio devices-1).
 *  Only valid after a successfully initializing the audio subsystem.
 *  The values returned by this function reflect the latest call to
 *  SDL_GetNumAudioDevices(); recall that function to redetect available
 *  hardware.
 *
 *  The string returned by this function is UTF-8 encoded, read-only, and
 *  managed internally. You are not to free it. If you need to keep the
 *  string for any length of time, you should make your own copy of it, as it
 *  will be invalid next time any of several other SDL functions is called.
 */
const char * SDL_GetAudioDeviceName(int index,
                                                           int iscapture);


/**
 *  Open a specific audio device. Passing in a device name of NULL requests
 *  the most reasonable default (and is equivalent to calling SDL_OpenAudio()).
 *
 *  The device name is a UTF-8 string reported by SDL_GetAudioDeviceName(), but
 *  some drivers allow arbitrary and driver-specific strings, such as a
 *  hostname/IP address for a remote audio server, or a filename in the
 *  diskaudio driver.
 *
 *  \return 0 on error, a valid device ID that is >= 2 on success.
 *
 *  SDL_OpenAudio(), unlike this function, always acts on device ID 1.
 */
SDL_AudioDeviceID  SDL_OpenAudioDevice(const char
                                                              *device,
                                                              int iscapture,
                                                              const
                                                              SDL_AudioSpec *
                                                              desired,
                                                              SDL_AudioSpec *
                                                              obtained,
                                                              int
                                                              allowed_changes);



/**
 *  \name Audio state
 *
 *  Get the current audio state.
 */
/* */
alias SDL_AudioStatus = int;
enum : SDL_AudioStatus
{
    SDL_AUDIO_STOPPED = 0,
    SDL_AUDIO_PLAYING,
    SDL_AUDIO_PAUSED
}
SDL_AudioStatus  SDL_GetAudioStatus();

SDL_AudioStatus 
SDL_GetAudioDeviceStatus(SDL_AudioDeviceID dev);
/* *//*Audio State*/

/**
 *  \name Pause audio functions
 *
 *  These functions pause and unpause the audio callback processing.
 *  They should be called with a parameter of 0 after opening the audio
 *  device to start playing sound.  This is so you can safely initialize
 *  data for your callback function after opening the audio device.
 *  Silence will be written to the audio device during the pause.
 */
/* */
void  SDL_PauseAudio(int pause_on);
void  SDL_PauseAudioDevice(SDL_AudioDeviceID dev,
                                                  int pause_on);
/* *//*Pause audio functions*/

/**
 *  This function loads a WAVE from the data source, automatically freeing
 *  that source if \c freesrc is non-zero.  For example, to load a WAVE file,
 *  you could do:
 *  \code
 *      SDL_LoadWAV_RW(SDL_RWFromFile("sample.wav", "rb"), 1, ...);
 *  \endcode
 *
 *  If this function succeeds, it returns the given SDL_AudioSpec,
 *  filled with the audio data format of the wave data, and sets
 *  \c *audio_buf to a malloc()'d buffer containing the audio data,
 *  and sets \c *audio_len to the length of that audio buffer, in bytes.
 *  You need to free the audio buffer with SDL_FreeWAV() when you are
 *  done with it.
 *
 *  This function returns NULL and sets the SDL error message if the
 *  wave file cannot be opened, uses an unknown data format, or is
 *  corrupt.  Currently raw and MS-ADPCM WAVE files are supported.
 */
SDL_AudioSpec * SDL_LoadWAV_RW(SDL_RWops * src,
                                                      int freesrc,
                                                      SDL_AudioSpec * spec,
                                                      Uint8 ** audio_buf,
                                                      Uint32 * audio_len);


/**
 *  This function frees data previously allocated with SDL_LoadWAV_RW()
 */
void  SDL_FreeWAV(Uint8 * audio_buf);

/**
 *  This function takes a source format and rate and a destination format
 *  and rate, and initializes the \c cvt structure with information needed
 *  by SDL_ConvertAudio() to convert a buffer of audio data from one format
 *  to the other.
 *
 *  \return -1 if the format conversion is not supported, 0 if there's
 *  no conversion needed, or 1 if the audio filter is set up.
 */
int  SDL_BuildAudioCVT(SDL_AudioCVT * cvt,
                                              SDL_AudioFormat src_format,
                                              Uint8 src_channels,
                                              int src_rate,
                                              SDL_AudioFormat dst_format,
                                              Uint8 dst_channels,
                                              int dst_rate);

/**
 *  Once you have initialized the \c cvt structure using SDL_BuildAudioCVT(),
 *  created an audio buffer \c cvt->buf, and filled it with \c cvt->len bytes of
 *  audio data in the source format, this function will convert it in-place
 *  to the desired format.
 *
 *  The data conversion may expand the size of the audio data, so the buffer
 *  \c cvt->buf should be allocated after the \c cvt structure is initialized by
 *  SDL_BuildAudioCVT(), and should be \c cvt->len*cvt->len_mult bytes long.
 */
int  SDL_ConvertAudio(SDL_AudioCVT * cvt);

enum SDL_MIX_MAXVOLUME = 128;
/**
 *  This takes two audio buffers of the playing audio format and mixes
 *  them, performing addition, volume adjustment, and overflow clipping.
 *  The volume ranges from 0 - 128, and should be set to ::SDL_MIX_MAXVOLUME
 *  for full audio volume.  Note this does not change hardware volume.
 *  This is provided for convenience -- you can mix your own audio data.
 */
void  SDL_MixAudio(Uint8 * dst, const Uint8 * src,
                                          Uint32 len, int volume);

/**
 *  This works like SDL_MixAudio(), but you specify the audio format instead of
 *  using the format of audio device 1. Thus it can be used when no audio
 *  device is open at all.
 */
void  SDL_MixAudioFormat(Uint8 * dst,
                                                const Uint8 * src,
                                                SDL_AudioFormat format,
                                                Uint32 len, int volume);

/**
 *  \name Audio lock functions
 *
 *  The lock manipulated by these functions protects the callback function.
 *  During a SDL_LockAudio()/SDL_UnlockAudio() pair, you can be guaranteed that
 *  the callback function is not running.  Do not call these from the callback
 *  function or you will cause deadlock.
 */
/* */
void  SDL_LockAudio();
void  SDL_LockAudioDevice(SDL_AudioDeviceID dev);
void  SDL_UnlockAudio();
void  SDL_UnlockAudioDevice(SDL_AudioDeviceID dev);
/* *//*Audio lock functions*/

/**
 *  This function shuts down audio processing and closes the audio device.
 */
void  SDL_CloseAudio();
void  SDL_CloseAudioDevice(SDL_AudioDeviceID dev);

/**
 * \return 1 if audio device is still functioning, zero if not, -1 on error.
 */
int  SDL_AudioDeviceConnected(SDL_AudioDeviceID dev);

/**
 *  Queue more audio on non-callback devices.
 *
 *  (If you are looking to retrieve queued audio from a non-callback capture
 *  device, you want SDL_DequeueAudio() instead. This will return -1 to
 *  signify an error if you use it with capture devices.)
 *
 *  SDL offers two ways to feed audio to the device: you can either supply a
 *  callback that SDL triggers with some frequency to obtain more audio
 *  (pull method), or you can supply no callback, and then SDL will expect
 *  you to supply data at regular intervals (push method) with this function.
 *
 *  There are no limits on the amount of data you can queue, short of
 *  exhaustion of address space. Queued data will drain to the device as
 *  necessary without further intervention from you. If the device needs
 *  audio but there is not enough queued, it will play silence to make up
 *  the difference. This means you will have skips in your audio playback
 *  if you aren't routinely queueing sufficient data.
 *
 *  This function copies the supplied data, so you are safe to free it when
 *  the function returns. This function is thread-safe, but queueing to the
 *  same device from two threads at once does not promise which buffer will
 *  be queued first.
 *
 *  You may not queue audio on a device that is using an application-supplied
 *  callback; doing so returns an error. You have to use the audio callback
 *  or queue audio with this function, but not both.
 *
 *  You should not call SDL_LockAudio() on the device before queueing; SDL
 *  handles locking internally for this function.
 *
 *  \param dev The device ID to which we will queue audio.
 *  \param data The data to queue to the device for later playback.
 *  \param len The number of bytes (not samples!) to which (data) points.
 *  \return zero on success, -1 on error.
 *
 *  \sa SDL_GetQueuedAudioSize
 *  \sa SDL_ClearQueuedAudio
 */
int SDL_QueueAudio(SDL_AudioDeviceID dev, const void *data, Uint32 len);

/**
 *  Dequeue more audio on non-callback devices.
 *
 *  (If you are looking to queue audio for output on a non-callback playback
 *  device, you want SDL_QueueAudio() instead. This will always return 0
 *  if you use it with playback devices.)
 *
 *  SDL offers two ways to retrieve audio from a capture device: you can
 *  either supply a callback that SDL triggers with some frequency as the
 *  device records more audio data, (push method), or you can supply no
 *  callback, and then SDL will expect you to retrieve data at regular
 *  intervals (pull method) with this function.
 *
 *  There are no limits on the amount of data you can queue, short of
 *  exhaustion of address space. Data from the device will keep queuing as
 *  necessary without further intervention from you. This means you will
 *  eventually run out of memory if you aren't routinely dequeueing data.
 *
 *  Capture devices will not queue data when paused; if you are expecting
 *  to not need captured audio for some length of time, use
 *  SDL_PauseAudioDevice() to stop the capture device from queueing more
 *  data. This can be useful during, say, level loading times. When
 *  unpaused, capture devices will start queueing data from that point,
 *  having flushed any capturable data available while paused.
 *
 *  This function is thread-safe, but dequeueing from the same device from
 *  two threads at once does not promise which thread will dequeued data
 *  first.
 *
 *  You may not dequeue audio from a device that is using an
 *  application-supplied callback; doing so returns an error. You have to use
 *  the audio callback, or dequeue audio with this function, but not both.
 *
 *  You should not call SDL_LockAudio() on the device before queueing; SDL
 *  handles locking internally for this function.
 *
 *  \param dev The device ID from which we will dequeue audio.
 *  \param data A pointer into where audio data should be copied.
 *  \param len The number of bytes (not samples!) to which (data) points.
 *  \return number of bytes dequeued, which could be less than requested.
 *
 *  \sa SDL_GetQueuedAudioSize
 *  \sa SDL_ClearQueuedAudio
 */
 Uint32 SDL_DequeueAudio(SDL_AudioDeviceID dev, void *data, Uint32 len);
 
/**
 *  Get the number of bytes of still-queued audio.
 *
 *  For playback device:
 *
 *    This is the number of bytes that have been queued for playback with
 *    SDL_QueueAudio(), but have not yet been sent to the hardware. This
 *    number may shrink at any time, so this only informs of pending data.
 *
 *    Once we've sent it to the hardware, this function can not decide the
 *    exact byte boundary of what has been played. It's possible that we just
 *    gave the hardware several kilobytes right before you called this
 *    function, but it hasn't played any of it yet, or maybe half of it, etc.
 *
 *  For capture devices:
 *
 *    This is the number of bytes that have been captured by the device and
 *    are waiting for you to dequeue. This number may grow at any time, so
 *    this only informs of the lower-bound of available data.
 *
 *  You may not queue audio on a device that is using an application-supplied
 *  callback; calling this function on such a device always returns 0.
 *  You have to queue audio with SDL_QueueAudio()/SDL_DequeueAudio(), or use
 *  the audio callback, but not both.
 *
 *  You should not call SDL_LockAudio() on the device before querying; SDL
 *  handles locking internally for this function.
 *
 *  \param dev The device ID of which we will query queued audio size.
 *  \return Number of bytes (not samples!) of queued audio.
 *
 *  \sa SDL_QueueAudio
 *  \sa SDL_ClearQueuedAudio
 */
Uint32 SDL_GetQueuedAudioSize(SDL_AudioDeviceID dev);

/**
 *  Drop any queued audio data. For playback devices, this is any queued data
 *  still waiting to be submitted to the hardware. For capture devices, this
 *  is any data that was queued by the device that hasn't yet been dequeued by
 *  the application.
 *
 *  Immediately after this call, SDL_GetQueuedAudioSize() will return 0. For
 *  playback devices, the hardware will start playing silence if more audio
 *  isn't queued. Unpaused capture devices will start filling the queue again
 *  as soon as they have more data available (which, depending on the state
 *  of the hardware and the thread, could be before this function call
 *  returns!).
 *
 *  This will not prevent playback of queued audio that's already been sent
 *  to the hardware, as we can not undo that, so expect there to be some
 *  fraction of a second of audio that might still be heard. This can be
 *  useful if you want to, say, drop any pending music during a level change
 *  in your game.
 *
 *  You may not queue audio on a device that is using an application-supplied
 *  callback; calling this function on such a device is always a no-op.
 *  You have to queue audio with SDL_QueueAudio()/SDL_DequeueAudio(), or use
 *  the audio callback, but not both.
 *
 *  You should not call SDL_LockAudio() on the device before clearing the
 *  queue; SDL handles locking internally for this function.
 *
 *  This function always succeeds and thus returns void.
 *
 *  \param dev The device ID of which to clear the audio queue.
 *
 *  \sa SDL_QueueAudio
 *  \sa SDL_GetQueuedAudioSize
 */
void SDL_ClearQueuedAudio(SDL_AudioDeviceID dev);
