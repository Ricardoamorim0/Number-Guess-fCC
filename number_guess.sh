#!/bin/bash

PSQL="psql --username=freecodecamp --dbname=number_guess --tuples-only -c"
RANDOM_NUMBER=$((1 + $RANDOM%1000))
GUESSES=1

echo "Enter your username:"
read USERNAME

USER_ID=$($PSQL "SELECT user_id FROM users WHERE username='$USERNAME';")
if [[ -z $USER_ID ]]
then
  INSERT_USER_RESULT=$($PSQL "INSERT INTO users(username) VALUES ('$USERNAME');")
  USER_ID=$($PSQL "SELECT user_id FROM users WHERE username='$USERNAME';")
fi

echo $($PSQL "SELECT games_played, best_game FROM users WHERE username='$USERNAME';") | while read GAMES_PLAYED BAR BEST_GAME
do
  if [[ $GAMES_PLAYED == 0 ]]
  then
    echo "Welcome, $USERNAME! It looks like this is your first time here."
  else
    echo "Welcome back, $USERNAME! You have played $GAMES_PLAYED games, and your best game took $BEST_GAME guesses."
  fi
done

echo "Guess the secret number between 1 and 1000:"

FIND_NUMBER() {
  read SECRET_NUMBER

  if [[ ! $SECRET_NUMBER =~ ^[0-9]+$ ]]
  then
    echo "That is not an integer, guess again:"
    FIND_NUMBER
  elif [[ $SECRET_NUMBER -eq $RANDOM_NUMBER ]]
  then
    echo $($PSQL "SELECT best_game, games_played FROM users WHERE user_id=$USER_ID;") | while read BEST_GUESS BAR GAMES_PLAYED
    do
      if [[ $GAMES_PLAYED -eq 0 || $BEST_GUESS -gt $GUESSES ]]
      then
        UPDATE_DATA_RESULT=$($PSQL "UPDATE users SET best_game=$GUESSES, games_played=games_played+1 WHERE user_id=$USER_ID;")
      else
        UPDATE_DATA_RESULT=$($PSQL "UPDATE users SET games_played=games_played+1 WHERE user_id=$USER_ID;")
      fi
    done

    echo "You guessed it in $GUESSES tries. The secret number was $RANDOM_NUMBER. Nice job!"
  elif [[ $SECRET_NUMBER -lt $RANDOM_NUMBER ]]
  then
    echo "It's higher than that, guess again:"
    ((GUESSES++))
    FIND_NUMBER
  elif [[ $SECRET_NUMBER -gt $RANDOM_NUMBER ]]
  then
    echo "It's lower than that, guess again:"
    ((GUESSES++))
    FIND_NUMBER
  fi
}

FIND_NUMBER