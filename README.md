# Simple Castbar

## Dependencies

This addon requires the following libraries:

* [LibAddonMenu](https://www.esoui.com/downloads/info7-LibAddonMenu.html)
* [LibCombat](https://www.esoui.com/downloads/info2528-LibCombat.html)

They are not included in the release and have to be downloaded manually.

## Description

After having existed as an unfinished AddOn for more than a year, Simple CastBar is now publicly available. 

Its main function is to provide visual feedback on the skills you cast. 
The blue bar will fill up during the global cooldown or the cast time of your activated skill in synch with its animation. 

Additionally the cast bar tracks the input timing, providing feedback on your weaving (also known as animation cancelling). 
To this end, a red line will indicate the timing of your light attack (LA), while a green line shows the timing of your skill cast. 
A grey line marks the target time point when the global cool down or cast time of the previous skill finishes. 
The position of the grey line is calculated based on the delay between your input (pressing the button or key) and the actual start of the animation of the client for your previous cast. 
So the goal is to press your LA button a little bit before the grey line and the skill as close as possible after it.
If you successfully manage to cast you next skill within a threshold time of the previous one finishing (80 milliseconds on default, adjustable in the settings) a green border around the cast bar will indicate this. If you're too slow but at least cast a LA and a Skill, a yellow border will appear. If you cast your skill to early or forget to cast a light attack, so that no LA will be woven between the two skill casts, a red border will appear.

The tech that is used for the cast bar is the same as for the weaving statistics of Combat Metrics.

## Known Issues
* Cancelling cast time skills, is currently not represented by the castbar.
* When the connection fluctuates a lot, the position of the grey line will vary, and LAs will be missed despite the casts being timed properly. This can't be avoided since the actual delay for your next cast is unknown and if it is processed faster than the previous one, it might be cast too early from the servers point of view, cancelling your LA. In this case it is recommended to intentionally delay your casts.
* Some skills, especially long channelling skills, like Templar and Arcanist beams don't allow precasting of LAs. For them, the LA has to be cast after the grey line.

*Solinur (PC-EU)*
