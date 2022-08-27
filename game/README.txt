Game: Saving Kittens!
Author: Haolan Zhan
Class: CE205


Open game.exe to run

Background: You have probably heard of the term raining cats and dogs. Well, due to climate destabalization occuring from Human's reckless 
			use of the Earth, it has suddenly started to rain cats! Not only that, due to the Earth's weakening ozone layer, 
			space bombs are making it past the atmosphere and are falling down on Earth! It is up to you to save the cute felines, while
			avoiding the bombs! 
			
Gameplay instructions for assignment 5: 
		1) The game loads with the pause/start screen 
		2) Press 'P' to start playing the game
		3) Press 'SPACE' at any time to pause the game. Press 'P' to resume playing. 
		4} Pree 'R' at any time to restart the game. 
		5) Cats will begin to fall from the sky. 
		6) Use the mouse cursor to move the pillow horrizontally in order to catch the cats! 
		7) Catch the cats by making contact with the cat using the pillow 
		8) Bombs will fall from the sky 
		9) Avoid making contact with the bombs using the pillow - GAME OVER if you do! 
		10) Points are earned for catching each cat - first cat is worth 100 points, and each subsequent cat is worth 20 more than the previous 
		11) Points are earned for staying alive (not getting GAME OVER) - There will be 50 points added at regularly decreasing intervals of time 
		12) Points are earned for missing bombs (when bombs fall through the screen) - 100 points added per bomb missed 
		13) Points are deducted for missing cats (when cats fall through the screen) - 100 points deducted per cat missed  
		14) Use the left/right arrow keys, or the 'A' and 'D' button to move the fan horizentally 
		15) If the fan is placed directly underneath a cat, the cat will fall slower! 
		16) Beat the game by avoiding all the bombs
		17) Earn the highest score by catching all the cats (and avoiding all the bombs) 
		18) Good Luck! 
		
Mandatory Features for scoring: 
		Basic 
		1) collision detection between pillow and cats, pillow and bombs 
		2) multiple sprites (bomb, cat, fan, pillow, background) 
		3) Reward: greater points
		4) Punishment: GAME OVER or lesser points 
		5) Pause feature using space bar, and then resume using 'P'
		6) Pillow and Fan responds to player input 
		
		Advanced: 
		1) There is background music upon start up. There is sound effect when the player misses the cat. Since this halts the background music,
			pressing the SPACE bar to pause the game will restart the background music (until the next sound effect). Restarting the game 
			should also restart the background music (since the initial state of the game is paused).
			
			There is an explosion sound effect and a game over sound effect when the player looses 
			
			When testing in Virtual Box, sounds cannot be played immediately right after another sound plays (or if a sound is currently playing). 
			Hopefully, this is not an issue on an actual windows computer (and my virtual machine is just too slow too keep up). On my gameplay, 
			the first missed cat will not trigger the sound effect because the background music is playing. The explosion does not sound because 
			it is very close in temporal proximity to the game over sound. There are other similar glitches with sound not playing, but I assume 
			these are all non-existent on a real windows computer. 
			
		2) The cat and bombs fall with constant acceleration (gravity). The fan produces an upwards force to reduce acceleration for the cats 
		
		3) Since bombs and cats are falling, there are multiple in-flight projectiles 
		
		4) Complex scoring system: Points are earned/deducted for catching/missing cats, surviving, and missing bombs as described above. 
		
Other Features/Details
		
		States of the game: 
		
				The game will initially start in the paused state. There is a play state, a game-over state, and a beat-game state. The game can be 
			restarted at any time (reinitializes all vales, and return to paused state) 
			
		Cat objects 
		
				There is a struct of 30 cats, initialized with a random x position within the width of the screen, a random x velocity in a narrow range, 
			and a y position off the screen on the top. Each subsequent cat in the array has a higher score value, and a higher constant acceleration. 
			Cats will fall at regularly decreasing intervals of time (so that the last few cats will fall twice as soon as the first two cats). Cats 
			first fall upside down, and then upon contact with the pillow (if it occurs), the cat will flip right-side-up, and travel with a constant
			velocity off the screen. Cats will bounce of the sides of the screen if still falling. When the last cat falls, and leaves the screen 
			(either being caught or falling through the screen), the player has beat the game. 
			
		Bomb objects 
		
				There is a struct of 13 bombs, initialized with a random x position withen the width of the screen, a random x velocity in a narrow range, 
			and a y position off the screen on the top. Each bomb has a constant acceleration. Each subsequent bomb in the array will fall a regularly 
			decreasing intervals of time (so that 13 bombs will fall in the same time span in which it takes 30 cats to fall). Whenever a bomb is 
			released, the survival points will be added to the score. Bombs will bounce off the sides of the screen if still falling. The bomb will
			explode when making contact with a pillow, and this specific exploded bomb will be drawn at the GAME OVER screen.
			
		Pillow object 
				
				The pillow will follow the mouse. The pillow will be flattened upon collision with a cat, and will only be reset when a cat leaves 
			the screen after being caught. This was done because having the pillow return to normal when not in contact with a cat was a bit
			glitchy, since 30 cats are pretty much being looped instantaneously, and even if 1 cat is in contact with the pillow, the other 29
			cats are not, therefore the pillow would not always annimate to the flattened version. 
			
		Fan object
		
				The Fan will follow the arrow keys or AD keys. The fan will only act on a cat if it is directly below it. The fan will decrease the 
			acceleration by a factor of 32 during any duration of time when it is below a cat. The cat will resume to original acceleration when it moves
			off the vertical column where the fan resides. When testing, this does not produce a visible effect if the cat is already falling at a 
			decent velocity. Therefore, in addition to decreasing the acceleration, the fan will also apply a one-time decrease to the cat's vertical
			velocity. This velocity decrease will happen only once when the cat is over a fan, and will happen only once each time the cat re-appears over 
			the fan. This way, the effects of the fan is noticeable. 