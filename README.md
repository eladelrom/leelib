leelib
======

Open-source AS3 library, including Flv Encoder.  This implementation is meant for capturing entire application and not just the webcam.

March 28, 2013:
Author: Elad Elrom

Few things added in this fork:

1. Refactor project's libraries to fit AIR/Flex structure. Moved alchemy lib: flvEncodeHelper.c & flvEncodeHelper.swc to "lib" folder.
2. Added a Flex example (which can be useful for building AIR apps). Flex example shows how you can wrap other component in addition to the video itself, which can be found useful $
3. Added static RecorderHelper class, which helps delegate and move the code from the view so the implementation clean and readable for the Flex example.
4. Added VO class to hold the variable needed to record audio+video. The helper/VO can be used to refactor the pure AS example as well.
