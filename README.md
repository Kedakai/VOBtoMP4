# VOBtoMP4
A script, that converts all VOB files to a single MP4

What this script is able to do:
- recognize how much episodes are in a VIDEO_TS folder and manage to convert them all correctly.
- autodelete after converting (It's safe.)
- creating dynamic filenames (example: Tet will be Tet.mp4 and Breaking Bad will be: Breaking Bad_1.mp4, Breaking Bad_2.mp4...)
- build everything new mode (Recreates the hole structure and reconverts all available videos)
- Will copy all audio sources. 

There are some requirements as told in the script:
- Leave the script alone: It can only work perfectly if no names are changed between runs. 
- The Structure of the folders has to be like this: (Maybe i will update this to make it more dynamic):
    /home/Video/Tet/VIDEO_TS/files
    /home/Video/Tet 2/VIDEO_TS/files
- Script has to be startet from here, then:
    /home/Video/vobtomp4.sh
    
I think that this only makes sense with untouched-DVD's.

Oh and: Please do only use you'r own DVD's, that you've bought before. DO NOT COPY A DVD ILLEGAL.
