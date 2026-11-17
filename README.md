Output: AmongUsMenu.dylib (arm64 + arm64e).

Build once, however you like:

  GitHub   push this folder to a private repo, Actions -> build -> download
           the AmongUsMenu-dylib artifact, unzip it.
  Theos    cd here && export THEOS=~/theos && make
           take .theos/obj/AmongUsMenu.dylib

Install:

  1. In LiveContainer, long-press Among Us.
  2. Open its tweaks list.
  3. Import AmongUsMenu.dylib.
  4. Launch. Green C button, top-left.

The dylib checks its own bundle id and no-ops in any other app, so it is safe to
leave attached. Nothing needs to be placed inside the IPA.