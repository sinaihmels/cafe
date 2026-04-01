# 🍰 Cozy Bakery Deckbuilder – Game Design Documents

---

# 📘 DOCUMENT 1: FULL GAME DESIGN

## 🎯 Core Concept

A cozy roguelike deckbuilder where the player runs a bakery, crafting food through card combinations while managing customers and protecting their mental energy.

---

## 🔁 Core Gameplay Loop

### 🌅 Morning Phase

* Choose dough (defines playstyle)
* Adjust deck
* Buy equipment or cards

### ☀️ Shop Phase

* Customers arrive (encounters)
* Play cards using mana
* Create food and manage customer patience
* Survive until customer is satisfied

### 🌙 Evening Phase

* Earn rewards
* Gain new cards
* Unlock content

### 💀 Burnout Loop

* Player "burns out" instead of dying
* Lose deck and temporary buffs
* Keep dough unlocks, equipment, decorations

---

## ⚙️ Core Systems

### 🥐 Dough System

Defines playstyle per run

Examples:

* Sweet Dough → combo-heavy
* Laminated Dough → multi-step
* Savory Dough → efficient
* Sourdough → slow scaling

---

### 🃏 Card System

#### 🍫 Ingredient Cards

Add tags to food

* Chocolate
* Cinnamon Sugar
* Cheese

#### 🔥 Process Cards

Transform dough

* Bake
* Proof
* Slice

#### ✨ Technique Cards

Buffs and combo tools

* Double Batch
* Perfect Timing

#### 🛡️ Interaction Cards

Customer control

* Tell Joke
* Apologize

#### ☕ Utility Cards

* Gain mana
* Draw cards

---

### 🍽️ Tag-Based Food System

Food is created through tags rather than fixed recipes

Example:

* Customer wants: Sweet + Chocolate
* Player creates via cards

---

### ⚡ Resources

#### 🔵 Mana

* Used to play cards

#### ❤️ Stress (HP)

* Reduced by customers
* Reaching 0 ends run

#### ⭐ Reputation (Optional)

* Affects difficulty and rewards

---

## 👥 Customers (Enemies)

### Attributes

* Preferences (tags)
* Patience meter

### Types

* Patient
* Impatient
* Critic
* Chaotic
* Regular

---

## 👑 Bosses

### Examples:

#### Food Critic

* Extremely high expectations
* Large rewards

#### Rush Hour

* Multiple customers at once

#### Influencer

* Demands perfect aesthetic

#### Health Inspector

* Punishes mistakes heavily

---

## 🔥 Oven System

* Cards placed into oven resolve after turns
* Can be sped up or modified

---

## 🏠 Café System

### Decorations

* Cosmetic only

### Equipment (Permanent Buffs)

* Coffee Machine → +1 mana
* Better Oven → faster cooking
* Display Case → patience increase

---

## 📈 Progression

### Persistent

* Dough unlocks
* Equipment
* Decorations

### Reset

* Deck
* Buffs
* Money

---

## 🎨 Scenes / Biomes

### Starter Café

* Basic customers

### Busy Downtown

* Faster pacing

### Night Market

* Exotic requests

### Festival Day

* High pressure, high rewards

---
