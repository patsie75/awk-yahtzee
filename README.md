# awk-yahtzee
Yahtzee in GAWK

requires gawk version 5.0 or later (Using 'namespace')  


You have three rolls each turn. On the first two rolls you can 'hold' either one of the 5 die  

    hold 1/2/3/4/5: 135

Will hold dice 1, 3 and 5 but will reroll dice 2 and 4

After three dice rolls you are presented with a prompt:

    choose score:

Pick a number between 1 and 13, matching on your scorecard to add the score to this particular choice.

After 13 turns, each of your scorecard entries has been filled in and you will be presented with your total score.

