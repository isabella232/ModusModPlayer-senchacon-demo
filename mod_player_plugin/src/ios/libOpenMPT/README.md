
README
======

libopenmpt for iOS
======================


Instructions 
--------------
- Add the xcode project
- TODO: Fill in the rest ;)



A few words from the readme of the original MPT 1.16 source drop by Olivier
---------------------------------------------------------------------------

> The sound library was originally written to support VOC/WAV and MOD files under
> DOS, and supported such things as PC-Speaker, SoundBlaster 1/2/Pro, and the
> famous Gravis UltraSound.
> 
> It was then ported to Win32 in 1995 (through the Mod95 project, mostly for use
> within Render32).
> 
> What does this mean?
> It means the code base is quite old and is showing its age (over 10 years now)
> It means that many things are poorly named (CSoundFile), and not very clean, and
> if I was to rewrite the engine today, it would look much different.
> 
> Some tips for future development and cleanup:
> - Probably the main improvement would be to separate the Song, Channel, Mixer
> and Low-level mixing routines in separate interface-based classes.
> - Get rid of globals (many globals creeped up over time, mostly because of the
> hack to allow simultaneous playback of 2 songs in Modplug Player -> ReadMix()).
> This is a major problem for writing a DShow source filter, or any other COM
> object (A DShow source would allow playback of MOD files in WMP, which would be
> much easier than rewriting a different player).
> - The MPT UI code is MFC-based, and I would say is fairly clean (as a rough
> rule, the more recent the code is, the cleaner it is), though the UI code is
> tightly integrated with the implementation (this could make it somewhat more
> difficult to implement such things as a skin-based UI - but hey, if it was easy,
> I probably would have done it already :).
