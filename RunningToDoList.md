# Running Todo List

##  Enemies
* Enemies should not be satisfied by one pastry alone
* Multiple Enemies per day
* Enemies can gift decorations if they are extremely satisfied
* have a score system on how satisfied your customers are 
* Implement that very satisfied customers come more often (e.g. on multiple days)


## Dialogue
* Implement Dialogue system where the Customer tells us their order and maybe what whould make them extra happy
* Implement that when specific cards are played like "Tell Joke", "Apologize", "Compliment" this triggers the dialogue 
and gives the player options to choose from and different options determine how effective the effect of the card is


## Pastry
* Different pastries are more make the customer more satisfied, depending on maybe dough and tags
* One pastry is created at a time
Your current tags field seems to be doing two jobs at once:

card identity tags, like "ingredient" or "process"
pastry result tags, like "sweet" or "flaky"

That can get messy fast. I’d strongly recommend:

keep CardDef.tags for card classification
put pastry-changing behavior into effects

So for example:

Chocolate card tags: ["ingredient"]
effect: AddPastryTags(["sweet","chocolaty","luxurious","pretty"])

That will make your systems much easier to scale.

Also, status-like things such as warm, baked, burned, and proofed should probably be pastry states, not just plain tags. They behave differently from flavor tags like sweet or fruity.
