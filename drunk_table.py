import pandas as pd
import datetime

keep_open = True # for the while loop

def add_drink(joueur, pc_alcool=5, v_alcool=355, dt=datetime.datetime.now(), commentaires=""):
    # This function adds a drink instance to a csv file
    # It takes the input:
    # joueur (means player, as in dnd player): a string of the name of the drinker (as top be the same for the same person (even when drunk))
    # pc_alcool: a number (int or float) the percentage of alcohol in the drink
    # v_alcool: a number (int or float) the volume of the drink in milliliters
    # dt: datetime instance (by default this is the time it is called)
    table = pd.read_csv("drunk_table.csv", encoding='iso-8859-1') # importing the csv into a DataFrame variable
    table = table.append({"Datetime":dt, "Joueur":joueur, "% Alcool":pc_alcool, "Volume Alcool":v_alcool, "Alcool Pur":pc_alcool*v_alcool/100, "Commentaires":commentaires}, ignore_index=True) # adding a line in the dataframe
    table.set_index("Datetime") # set the index to the time
    table.to_csv("drunk_table.csv", index=False) # write the new dataframe with an added line to the csv

while keep_open:
    joueur = input("Joueur? ") # Enter the name of the drinker
    pc_al = float(input("% d'alcool? ")) # Enter alcohol percentage
    v_al = float(input("Volume d'alcool? (ml) ")) # Enter drink volume
    comm = input("Commentaires? ") # Add comments (the type of drink)
    dt = datetime.datetime.now() # Get the timestamp

    add_drink(joueur, pc_alcool=pc_al, v_alcool=v_al, dt=dt, commentaires=comm) # add the recorded info to the csv
    show_data = input("Montrer les données récoltées? (y ou n) ") # Show the data in terminal or not
    if show_data == "y":
        print(pd.read_csv("drunk_table.csv"))
    close_terminal = input("Fermer le terminal? (y ou n) ") # close the terminal or not
    print("\n")
    if close_terminal == "y":
        keep_open = False # if y was entered, the while loop stops and the terminal closes
