# awk-yahtzee
Yahtzee in GAWK

requires gawk version 5.0 or later (Using 'namespace')  


You have three rolls each turn. On the first two rolls you can 'hold' either one of the 5 die  

    hold 1-6: 555

Will hold three dice with a 5 but will reroll the remaining dice

![awk-yahtzee image01](/screenshots/awk-yahtzee01.png)


After three dice rolls you are presented with a prompt:

    choose score:

Pick a number between 1 and 13, matching on your scorecard to add the score to this particular choice.

![awk-yahtzee image02](/screenshots/awk-yahtzee02.png)

After 13 turns, each of your scorecard entries has been filled in and you will be presented with your total score.

Here's a YouTube video of the game: https://youtu.be/HhGhpCQTgu8
