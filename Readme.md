# WOTLK Pawn client with TBC gems included




## Original Readme:






Pawn
====

Pawn calculates scores for items that let you easily see which one is better for you.  It's completely customizable, and applicable to any class and situation: for example, it can help you discover that the ring with a higher item level but one stat you don't want (such as spirit for shamans), or the ring with the lower item level but all good stats.  It's that level of customization that makes it very different from more general mods like GearScore and more specialized mods like TankPoints.

Pawn is a mod for hardcore World of Warcraft players who agonize over stats and itemization.  Use the included Wowhead stat weight presets, import Pawn "scale tags" posted on forums, or start from scratch and come up with your own valuation scales.  If you're the kind of person who plans gear upgrades, builds Excel spreadsheets, installs Rawr, reads Elitist Jerks... well, Pawn might just be right up your alley.

I welcome your feedback—see the Notes section.

Installing Pawn
---------------

Pawn is installed like pretty much every other World of Warcraft mod on the planet.  Extract the contents of the zip file to your Add-ons folder, generally located in one of these locations:

`C:\Users\Public\Games\World of Warcraft\Interface\AddOns`  
`C:\Program Files\World of Warcraft\Interface\AddOns`  
`C:\Program Files (x86)\World of Warcraft\Interface\AddOns`

How Pawn works
--------------

Pawn works by reading the tooltips for items in-game, and annotating them with some useful information, based on your personal preferences.  Let's say that you're a shaman, and someone links the once-popular Molten Core tank shield Drillborer Disk in trade chat.  With Pawn installed and set up, you might see the following when clicking that link:

Drillborer Disk

Binds when picked up

Off Hand     Shield

2918 Armor

60 Block

+10 Stamina

Equip: When struck in combat inflicts 3 Arcane damage to the attacker.  (?)

Equip: Increases your block rating by 10.

Equip: Increases the block value of your shield by 23.

Healing: 31

PvP: 292

(?) Special effects were not included in the value.

There are a couple differences between a Pawn-enhanced item tooltip and the normal one.  The most obvious is the set of numbers at the bottom.  I've set up Pawn to calculate two different values for each item I come across: one for my healing gear set, and one for my PvP gear set.  When I'm healing in raids, I don't care too much about my armor, or my block stats.  So, this tank shield isn't very useful to me; it got a rating of 31 points.  In contrast, in PVP and solo combat, I care a lot more about armor—maybe someday it will help me manage to get a spell off versus a rogue before I die.  The value of this shield to me in a PVP situation is considerably higher: 292 points.

What are these points?  They're exactly what I like them to be.  Pawn lets you set up arbitrary valuation "scales" for every item you come across.  For each scale, you get to assign a point value to each of a wide variety of stats.  Pawn will then analyze the item for you, and quickly come up with a number score based on the criteria that you've set up.  Without having to configure anything, Pawn includes values appropriate for your class from Wowhead, so it's possible you may never need to configure anything else.

Not every possible property of an item can be given a value.  For example, the Drillborer Disk reflects 3 arcane damage to each enemy who hits the shield.  This isn't a common property for items in World of Warcraft to have, and Pawn doesn't know how to value that special effect.  It tells you this by adding a special (?) icon to that effect on the tooltip, and then adding a helpful message to the bottom.  When making the decision of whether or not to use Drillborer Disk, you'll need to keep that in mind; if you find another PvP shield that also gets a rating of about 292 points, then you should choose Drillborer, because it has an extra effect that wasn't taken into account for the rating.

Let's get started.  First, log into your character, making sure that the Pawn mod is enabled.  Once you log in, start hovering over items in your inventory, or click links in the trade channel.  When you hover over things like herbs and ores and quest items, you'll notice that the tooltip doesn't look any different than it used to; that's because those items don't have stats.  When you hover over equipment that you're wearing, though, you should see new lines at the bottom that list your class and spec.  Without any input from you, Pawn is assigning a score to every item in your inventory, using stat weights from Wowhead appropriate for your class.  For example, if you're a shaman, Pawn will enable elemental, enhancement, and resto PvE scales for your items.  If you see two gloves with a higher resto score, then the one with the higher score is most likely the best item for that spec.  The other item might, however, have a higher score according to the enhancement scale.  Each scale is independent, because each item is better for different things.

For items with gems or enchantments, you may see two numbers.  The second one is the "base value" for an item, which ignores enchantments and which gems you have in it.  Use the base values to see if an item is an upgrade for you.

It's quite possible to use Pawn right "out of the box," but you may want to customize its behavior after you try it out for a while.  So, without further ado, let's talk about customizing Pawn.

Scales
------

Each of your characters has a unique set of options for Pawn, and can have any number of valuation scales, which often (but not always) represent different sets of gear or situations you find your character in, or different talent specs.  A valuation scale has two things: a name, such as "Pawn value", and a list of stats and how many points each stat is worth.

The first thing you'll need to do is decide what you'll do with Pawn.  Many people can be perfectly happy just using the scales from Wowhead that come with Pawn, and not need to customize a thing.  But, you can customize Pawn to do much more.  You can make your own personal version of the Wowhead scales with slightly tweaked stat values, import scale values from Rawr, or even create a completely new scale:

*   One possibility is just having Pawn calculate the total attack power that an item will give you.  A feral druid in cat form gets two points of attack power per point of strength, one point of attack power per point of agility, one point of attack power per point of attack power on the item (of course), and no benefit from ranged attack power.  This druid could set up a scale called "attack power" that adds those numbers up automatically: Strength = 2, Agility = 1, Attack power = 1, Feral AP = 1, and Ranged AP = 0.
*   Many people have a set of resistance gear, but deciding between an item that has 15 resistance and another that has 10 resistance but also a bunch of nice stats can be hard.  You can set up a scale that helps you decide whether those extra few points of resistance are worth sacrificing all of those stats.

Or, maybe, someone has already shared a **Pawn scale tag** with you, so that you can use a scale that they created or found themselves.

Pawn Scale Tags
---------------

Scale tags are a handy way that you can share your Pawn scales with other people, similar to how you can share talent specs with others just by giving them a link to the WoW talent calculator.  A sample scale tag looks like this:

( Pawn: v1: "Total fire damage": SpellDamage=1, FireSpellDamage=1 )

Generally, they're considerably longer than that, but the overall format is still the same.  A scale tag includes the parentheses ( ) on the ends and everything in-between.

It's possible to use Pawn along with scale tags that other people have created and never have to do any custom calculations or work yourself.  Here's how you can use scale tags to share Pawn scales.

### Adding a Pawn scale that someone shared with you

You can easily add Pawn scales that someone else shared with you on a website as a scale tag to your own copy of Pawn.  Highlight the entire scale tab, including the parentheses ( ), and then press Ctrl+C to copy it to the clipboard.  Then, switch to WoW.  To access the Pawn configuration UI, open your character sheet and inventory (the **C** key) and click the Pawn button in the lower-right corner.  Or, type the following slash command:

`/pawn`

Click the **Scale** tab on this window, and then click **Import**.  A window will appear where you can paste the entire scale tag that you got from someone else.  Press Ctrl+V to paste a scale tag from the clipboard into this window.  Once you're done, click OK, and that scale will be added to your copy of Pawn.

*   You can't import a scale tag if the scale has the exact same name as a scale you already have.  For example, if you have a scale named "Pawn value", you can't import a new scale tag named "Pawn value".
*   Make sure that you get the whole scale tag, including the "(" at the beginning and the ")" at the end, or it won't work.

#### Using Rawr

The popular program Rawr can generate highly-customized Pawn scales for you, ready for import.  Open Rawr, load your character, and then find the **Slot** dropdown in the **Comparisons** tab on the right.   Click it and select **Relative stat values**.  Then, click the **Export** dropdown in the upper-right and click **Copy Pawn string to clipboard**.  You can then use the normal Import feature to add this scale to Pawn.  (Unfortunately, all scales that Rawr produces will be called "Rawr", so if you use Rawr for more than one class or spec, you'll need to rename the scale yourself.)

### Sharing a Pawn scale with others

You can share one of your Pawn scales with others by exporting it from the Scale tab of the Pawn configuration UI.  From here, choose the scale that you want to export (if you have more than one) from the **Select a scale** list, and then click **Export**.  A window will appear containing your entire scale tag, but most of it will be scrolled off to the left where you can't see it.  Press **Ctrl+C** to copy the scale tag to your clipboard.  Then, switch to your web browser or an instant message window, or wherever you'd like to share your Pawn scale, and press **Ctrl+V** to paste the tag to that window.

### Finding more Pawn scales

You can find more Pawn scales on the unofficial [Pawn Scales Resources Forum](http://pawnmod.trenchrats.com/index.php).  Or, try the Pawn page at [Curse](http://www.curse.com/downloads/details/8214/).  Or, build your own scale using the Wowhead stat weights as a starting point: just click **Copy** on the **Scale** tab to get started.

Setting up a custom Pawn scale for one of your characters
---------------------------------------------------------

You can customize your Pawn scale in the Pawn configuration UI.  To show it, click the Pawn button in the lower-right corner of the character inventory window (the **C** key), or type the following slash command:

`/pawn`

Nobody thinks all statistics are created equal.  Warrior tanks don't care about intellect and spirit.  Priests don't care about strength.  You can customize Pawn to only look at the stats that you care about.  Let's do it now.

The Pawn configuration UI has everything you need to make changes to your scale, as well as import scales from other people, export them so you can share yours with others, and create multiple new scales for different situations.  Right now, the "Pawn value" scale is selected and ready to be modified.

On the left, you see a long list of all of the different item stats that Pawn understands.  They're grouped into categories—the primary stats like Stamina and Intellect are at the top, weapon stats are another section, spell-related state are another, sockets for gems are another, and so on.  The default Pawn value scale that was created for you has a value for almost every stat.

So, let's make some changes.  Let's start with a new default scale and delete the stats that we don't care about.  Go to the **Scale** tab and click **Empty** and give it a name to create a new one.  Now you're on the **Values** tab and can customize the numbers.  If you're a melee class, you can get rid of intellect and spirit.  To do this, click on Intellect in the list on the left (it's near the top).  When you click on a stat, you see a little description about the stat to the right (there's not much to say about intellect), and a box where you can type a new value.  To get rid of intellect, either delete the number from the box, replace it with 0, or just click **Remove**.  Then, choose spirit from the list and delete it too.  You can delete any stats you don't care about, and you can change the value of any stat in the list.  (If you find yourself removing a lot of stats, you can also create a new empty scale and start from scratch.  That would probably be easier than deleting everything individually.  The downside is that you don't get to see the starting values we suggested for each stat.)

Cool.  You don't have to do anything complicated just yet; that should be fine.  Your changes will take effect immediately; you can hover over new items or click links in trade chat and you'll see updated values based on your newly-modified scale.  Once you have thing set up the way you like them, Pawn will be customized to exactly what you care about in items.

If you ever manage to really screw things up, you can click Delete to delete the scale you're working on, and then click New default to create a new scale from the defaults.  If you name it "Pawn value" you'll be right back where you started.

### Setting up a second Pawn scale

You aren't limited to just one scale or a few; you can set up as many as you like.  To do this, go to the Scale tab on the Pawn configuration UI and click **Empty** to start a new scale with no values for any stat, or **Defaults** to start a new scale using the defaults as a starting point.  When you have two different scales, Pawn will show two numbers on each item you hover over or click in chat.  You can have any number of scales; just choose the one that you want to work on in the configuration UI before you start making changes to the stats.

Comparing items
---------------

You can use Pawn to easily compare two items.  Open the Pawn UI and click the **Compare** tab.  Then, place an equippable item from your inventory in the empty box in the upper-right corner.  Once you do this, Pawn will automatically fill in the slot on the left with whichever item you currently have equipped in that slot.  (For example, if you put a cloak in the right slot, Pawn will automatically put your currently equipped cloak in the left slot.)  In the case of trinkets and rings, you can switch between both equipped items using buttons in the lower-left corner.

The Compare tab shows you a breakdown of the two items by stats, and makes it easy to tell which item is better by showing the total Pawn value for each item, and highlighting the item with the higher value.  Only stats in the currently selected scale appear in the stat breakdown, so if you're viewing two DPS axes but have a frost mage scale selected, the stat list will be pretty empty since your frost mage probably doesn't care about agility and expertise.

The Compare tab always compares the base versions of items, ignoring currently socketed gems and enchantments.  (Items with empty sockets will get points based on the gem that Pawn suggests putting in those sockets.)

#### Comparing an item that just dropped to what you currently have

If you're deciding whether to roll or bid on an item, you can't pick it up and put it in a slot in the Compare tab, but you can still easily compare it to what you already have.  Just right-click on an item's icon in the roll window to put it into the Compare tab.  Or, if the item was linked in trade chat, click on the link to open the item link, and then right-click on the window (tooltip) that appears.

#### Comparing items in AtlasLoot and other mods without clicking

You can also compare items without having to click on them, which is useful for items you see in mods such as AtlasLoot.  To do this, you'll need to set up key bindings to **Compare left item** and **Compare right item** in the Key Bindings window.  Pawn will try to bind the **\[** and **\]** (left bracket and right bracket) keys to those commands if those keys aren't already bound to something else, but you can customize the key bindings to whatever you want.

Once you have key bindings set up, hover over the left item and press the Compare left item key **\[**, and then hover over the right item and press the Compare right item key **\]**.  (If the item is "unsafe" in AtlasLoot, you need to right-click it to make it safe first.)

*   You can use Compare right item to evaluate an item upgrade that drops from the boss you're about to kill.  Pawn will automatically fill in the left item with whatever you have equipped.
*   You can use both Compare left item and Compare right item to see the stat difference between two different badge rewards or the current PVP season's Pendant of Dominance and Pendant of Subjugation.

Notes
-----

Well, hopefully that's enough to get you started.  If you're interested in customizing Pawn further, check out the **Options** tab of the Pawn UI, and rest of this document.

### Contacting the author

I'm interested in knowing what you think of Pawn, and what you use it for.  Bug reports and suggestions are cool too.  The best way to contact me is on the [Pawn page at Curse](http://www.curse.com/downloads/details/8214/), which I check daily.  You can also contact me through in-game mail: Vger on Azjol-Nerub (US), Horde.  (Just make sure that you keep a character on my server and check your mail, or I can't respond!)  Also, check out my [official site](http://www.vgermods.com/), where you can find links to all of my mods.

### Reporting bugs

When reporting bugs, it's helpful to be as specific as possible.  Does the problem always happen for you, or just sometimes?  Can you think of any mods that you're running that might be related?  Does the problem still occur if you disable all your mods except Pawn?  What item does it happen on?

WoW now hides interface error information from you by default.  Reenabling it in Interface Options would be helpful; the error text includes useful information about where the error occurred. Any information you can provide to help Vger track down the bug is great.

Please remember that Pawn is language-specific.  The official English version of Pawn only works on the English version of World of Warcraft.  The non-English versions are maintained by other people.

### Key bindings

In addition to the options in the Pawn UI, you can also set a key binding to open and close the Pawn UI.  Look for it in the list of key bindings under "Pawn."

### Making a backup

You can back up all of your custom scales.  Just type **/pawn backup** in the chat box, and a window will appear.  Press Ctrl+C to copy its contents to the clipboard.  Then, create or open a file on your computer where you'd like to save the backup, and press Ctrl+V to paste your scales to that file.  Save the file, and now you have a backup of all of your custom scales in case you accidentally delete them, or just want to share them all with someone else.

**Note:** The scale Import feature only lets you import a single scale at a time, so to restore your scales from this backup you'll have to copy and paste them one-by-one.

You can also back up your SavedVariables file.  Open your World of Warcraft folder, and then in that location there is a folder named WTF.  Open it, and then the folder inside it with your account name, and then the SavedVariables folder.  Look for the file named "Pawn.lua" and save a copy of that file to a safe location.

### The Wowhead scales

The Wowhead stat weights are used with permission.  If you have feedback on the scale values, please direct it to the appropriate [Wowhead Theorycrafting forum](Wowhead%20Theorycrafting%20forum) threads.

#### Hiding

It's easy to hide any of the Wowhead scales that you don't like from your tooltips.  Just select a scale from the list and then uncheck **Show in tooltips**.

If you want to hide all Wowhead scales on all of your characters and have them not even show up in the list of scales, you can delete the file Wowhead.lua that comes with Pawn.

#### Resetting

It's possible to customize the colors of the Wowhead scales.  If you'd like to undo any changes you've made to the Wowhead scales, you can execute these two commands at a chat window:

/script PawnResetProviderScales()  
/reload

### Developers

If you have a World of Warcraft mod that you'd like to integrate with Pawn, please consider getting in touch with me.  I may have suggestions that will make your life easier.  I've also made it possible for other developers to create their own "scale providers" that can feed stat weights into Pawn just like the Wowhead scales.  If you'd like to create your own scale provider, take a look at Wowhead.lua, and contact me if you have any questions, or suggestions on ways that Pawn could be improved to work with your mod better.  (I can't, of course, guarantee that I'll make changes, but I might be able to help.)

Item valuation notes
--------------------

Here are some notes that may help you while you're setting up your Pawn scales.

### Gems and socket bonuses

Pawn assumes that you'll fill in any item that has sockets with the gems that will maximize that item's value, whether it's using the best gems of the correct colors to get the socket bonus, or gems of all one color and ignoring the socket bonus. By default, Pawn will automatically assign a value to sockets for you, and will update those values as you change your scale. If you prefer, however, you can change the values assigned to sockets the same way you can change the values of any stats.

If you open the item socketing window, you'll notice that Pawn will add its suggestions on which gems to use to maximize the value of the item. If you socket the item with exactly those gems, the value won't change. If you use better gems, the value will go up, and if you use worse gems, the value will go down. You can see a full listing of which gems Pawn suggests for each of your scales on the Gems tab of the Pawn UI.

Socket values in your scales only apply to the base version of an item.  No points are awarded for empty sockets in the current version of an item.  (You should gem your items and not be such a scrub!)  So, for socketed items, the current value for the item will be _lower_ than the base value.  This makes it easy to compare socketed items with non-socketed items based on their _potential_ stats—just always compare the base values of the two items. The Compare tab already does that for you.

Meta gems are also special, since they contain both stats and a secondary effect. You can assign a value to both parts individually, though by default Pawn will automatically pick a value for the stats portion of the gem for you.

By default, Pawn assumes that you'll use rare-quality (blue) level 80 gems.  You can change this for each of your scales individually on the Gems tab.  The following table shows how many stats the gems of each "tier" have.

_Gems at level 70_

**Gem quality**

**Number of base stats**

White (vendor)

4

Green (crafted)

6

Blue (crafted)

8

Epic (BoP heroic)

9

Epic (raid crafted)

10

Epic (BoP JC-only crafted)

12

  

_Gems at level_ 80

**Gem quality**

**Number of base stats**

Green (crafted)

12

Green (perfect crafted)

14

Blue (crafted)

16

Epic (crafted)

20

Epic (BoP JC-only crafted)

34

  

_Gems at level_ 85

**Gem quality**

**Number of base stats**

Green (crafted)

30

Blue (crafted)

40

Epic (BoP JC-only crafted)

67

Blue (BoP Engineer crafted)

132

### Resistances

For resistances, there's an "all resistances" stat and individual resistances.  The +3 All Resistances cloak enchantment would add three points of "all resistances" to the cloak, but no points of "fire resistance."  If you're putting together a scale for fire resistance, give points to both "all resistances" and "fire resistances."

### Weapon speed

Weapon speed can work a little differently than the other stats.  Some people value weapon speed based on how much faster or slower a weapon is than a particular speed.  The "speed baseline" stat (which isn't really a stat, per se) lets you choose this baseline speed, instead of 0, which is the speed baseline if you don't pick a different one.  For example, to give an item 1 point for every tenth of a second slower than 2.9 seconds per swing (useful for, say, enhancement shamans), set speed to 10 (10 = 1 / 0.1) and speed baseline to 2.9.  If you value faster weapons, pick your preferred speed baseline and then set the value speed to be negative, because higher numbers for speed are bad for you.

Speed baseline shows up in the "special weapon stats" category.

### Special weapon stats

If you want to value different types of weapons differently, don't use the regular DPS, minimum damage, maximum damage, and speed stats; instead, use the ones in the "special weapon stats" category at the end of the list.  For example, if you're a hunter, you might value ranged DPS much higher than melee DPS, since most of your damage comes from ranged attacks.

You won't want to use all of the weapon min damage, max damage, and DPS stats all at once.

*   Do you care about top-end damage only?  Use the max damage stats.  (max damage, 1H: max damage, Ranged: max damage, ...)
*   Do you care about damage per second only?  Use the DPS stats.  (DPS, 1H: DPS, Ranged: DPS, ...)
*   Do you care about only melee weapons in general, but not which hand?  Use the Melee stats.  (Melee: min damage, Melee: DPS, ...)
*   Do you care about the top end damage of all melee weapons that fit in your main hand?  Use MH: max damage _and_ 1H: max damage.
*   If you use the specialized versions of stats, don't also use the general ones.  For example, if you use Melee: DPS, don't also use DPS.  If you use Melee: min damage and/or Melee: max damage, you probably don't want to also use Melee: DPS.
*   The OH: DPS stat and other off hand-related stats do not take into account the decreased damage and hit rate of off-hand weapons.  The information is, as always, pulled straight from the tooltip.
*   If you care about average damage versus minimum and maximum damage, take the value you would have assigned to average damage if it existed as a stat, and add half to minimum damage and half to maximum damage.  For example, if you wanted to set Ranged: average damage to 10, but then found out that Ranged: average damage doesn't exist, set Ranged: min damage to 5 and Ranged: max damage to 5 instead.

### Armor

Most classes and specs will want to assign a single value to armor value.  However, feral druids and death knights have abilities and talents that multiply their armor by a certain percentage.  These abilities only multiply armor found on cloth (including cloaks), leather, mail, and plate armor ("base armor"), and not weapons, trinkets, rings, necklaces, enchantments, and armor kits ("bonus armor").  These classes can value the two types of armor separately by giving values to the appropriate stats.  If they do, they should not assign a value to the normal "armor" stat, or armor will be counted twice.

Please note that items that have bonus armor (in green text) will have the full armor value reported as base armor even though some is considered bonus armor by the game.  There is currently no way for mods to know how much of that armor value is base and how much is bonus.

### Normalizing values (like Wowhead)

With the "Normalize values" option disabled (the default), Pawn calculates values by multiplying each stat on an item by the value of that stat in each of your scales.  If you enable this option, Pawn will take that number and divide it by the sum of _all_ of the stat values in each of your scales.  This helps to compensate for how some scales might use numbers that average out to about 1.0, and others use numbers in the tens.

For example, if your scale were ( Stamina = 1, Intellect = 2, Crit rating = 1 ), then Wowhead would divide the item's total value by 4.  An item with 10 Stamina, 10 Intellect, and 20 Crit rating would have a value of 50 with this option off, and 12.5 with this option on.

### Special effects (?)

It's normal for certain special item effects to be listed with an icon (?).  You need to decide how important that effect is to you yourself.  For example, Pawn doesn't have a value for "Equip: Increases the effect that healing and mana potions have on the wearer by 40%" because only a few items do that.  You'll need to decide how to adjust that item's value yourself, based on how much benefit you receive from that special effect.

#### Set bonuses

Set bonuses are completely ignored by Pawn, and they won't get the special effect icon. You'll need to take them into account when deciding between an item that would give you a set bonus and an item that would not.

Mod support
-----------

Have a favorite mod that doesn't seem to work with Pawn?  Let me know.  I may not be able to add support for your favorite, but I might be able to suggest a replacement, or update Pawn to work better in a future version for popular mods.

### Mods that have been tested and work with Pawn

This is not a conclusive list.  If any of these mods doesn't seem to be working with Pawn, please make sure that you have the latest version of both it and Pawn.

*   Ackis Recipe List
*   AtlasLoot
*   Armory
*   CowTip
*   EQCompare
*   EquipCompare
*   FuBar
*   ItemSync
*   Link Wrangler
*   LootLink
*   Mendeleev
*   MobInfo-2
*   MonkeyQuest
*   MultiTips
*   Outfitter
*   Rating Buster
*   Skinner
*   Spyglass
*   tdItemTip
*   tekKompare

Release history
---------------

### Version 1.3.12

*   A bunch of new fixes to make Pawn work on the Cataclysm beta and the 4.0 PTRs.  This version also works fine on live realms.
    *   Mastery rating now works again.
    *   The problem where Pawn would hang after scanning approximately 50 items has been resolved.
    *   **Known issue:** The suggested gems for your scales are still based on the colors and cuts of gems available in patch 3.3.

### Version 1.3.11

*   Fixed an embarrassing typo that caused staves and polearms to not get Pawn values for classes that cannot also use two-handed swords, axes, and maces (everyone but warriors, I guess?).

### Version 1.3.10

*   Stats with negative values will no longer be taken into account when normalizing item values.  (For example, if a scale is Stamina = 10, Intellect = 5, Spirit = -10, then all values for that scale will be divided by 15, not 5.)
*   You can now mark stats as "unusable."  Items that have that stat on them will get no value for that scale.  For example, a scale for shamans can mark plate as unusable, and then all plate armor will get no value for that scale since shamans can't wear it.
*   The built-in scales now take advantage of the unusable stats feature, so unequippable items will not receive values.  (Your character's current level is not taken into account for this, so for example low-level shamans and hunters will still get values on mail items even though they can't wear mail until level 40.)
*   There are now separate stats for the one-handed and two-handed versions of axes, maces, and swords.  Existing scales that had a value for those weapon types will now only have a value for the one-handed version of those weapon types and will need to be updated manually.
*   Hopefully fixed the bug that a few people were seeing where they sometimes could not select scales.  I finally ran into it myself and tried an on-the-spot fix that worked for me.

### Version 1.3.9

*   Improved the appearance of the Pawn UI.  It's now no longer translucent, so it should be easier to read the text in certain circumstances.

### Version 1.3.8

*   Implemented additional performance enhancements so that Pawn uses even less memory and CPU time.  Having the Wowhead scales loaded now increases Pawn's memory and CPU usage by only a negligible amount, so I don't recommend disabling them anymore.
*   Added an arrow icon to the best item shown on the Compare tab to make it clearer at a glance and for colorblind people.

### Version 1.3.7

*   Fixed a bug where Pawn wouldn't recalculate which gems were best for a scale after chanigng stat values until the next time you logged in.
*   Fixed a separate bug where sometimes the display of socket values that were calculated automatically (as opposed to manually set) would not display correctly, even if they were properly calculated.

### Version 1.3.6

*   Thanks to some gnomish performance engineering, Pawn now uses about 95% less CPU time during login, which should reduce your login times by a second or two.
*   Added a new scale from Wowhead for arms warriors.
*   Changed the (\*) warning message to be a little clearer, and now it has a new (?) icon.  Pawn now calls item properties that it doesn't recognize "special effects."
*   Fixed a bug where the item special effect warning message wasn't showing up even when enabled.
*   Fixed a bug that might occur after the Wowhead scales (or any scales from a "plugin" of any sort) were disabled by deleting Wowhead.lua.

### Version 1.3.5

*   Changed a bunch of text to make it even easier for new users to get started with Pawn.
*   The default for new users of Pawn is now to only show the base values of items.  If you're already using Pawn and have current item values shown, your settings won't be changed and you'll still see both numbers.
*   Rearranged the list of stats on the Values tab so that more common stats are easier to find, and really rare stats like raw health aren't wasting prime screen real estate.
*   Added support for items with mastery rating for those of you in the Cataclysm beta.  (Untested.)

### Version 1.3.4

*   Fixed an issue for patch 3.3.5 that prevented you from linking gems from the Gems tab.

### Version 1.3.3

*   Added a very small value for Stamina for Wowhead scales that did not already include Stamina.  This will help prevent certain very odd gems from appearing as suggestions in the Gems tab.  (For example, some DPS scales did not include values for any blue stat, so the ret pally Gems tab included a gem with Spirit!)
*   Fixed a bug where Pawn disabled the Blizzard UI's item comparison tooltip that appears when you hold down the shift key while your mouse is over an item link window.

### Version 1.3.2

*   Fixed a bug where the Export button would generate an invalid scale tag for the Wowhead scales.  Now you can properly export the Wowhead scales just like your own.

### Version 1.3.1

*   Fixed a bug where the Pawn socketing suggestions window would not show the proper name of Wowhead scales.

### Version 1.3

**Important!**  After upgrading to Pawn 1.3, your Pawn settings and scales will be upgraded and will no longer be visible in older versions of Pawn.  If you need to revert to an older version of Pawn, use the new /pawn backup command to make a backup copy of your scales that you can save in a file on your computer.

*   You can now see and edit all of your scales in the Pawn UI, regardless of which character you're currently on.  (You'll need to log into each of your characters once first.)  Each of your scales can be shown in tooltips for just one or none of your characters (like in previous versions), or you can have a scale show up in the tooltips for multiple different characters.
*   All of the stat weight presets from Wowhead are now included with Pawn, so you can immediately start using it without needing to import or create any scales if you don't feel like customizing.  The Wowhead scales can't be changed, but if you want to use them as a starting point for your own scales you can copy them and modify the copy.
    *   If you have feedback for the Wowhead scales, please see the [Wowhead Theorycrafting forum](http://www.wowhead.com/?forums&board=20).
*   The new Scale tab now contains most of the per-scale options (such as whether it shows up on your character's tooltips), as well as the options for importing, exporting, and creating scales.  The Values tab (previously the Scales tab) is now a bit simpler.
*   The list of scales now appears in a pane to the left of the Pawn UI instead of in a dropdown.  The scales that are visible on the current character's tooltips will appear at the top of the list.
*   The "Normalize values (like Wowhead)" option can now be set individually for each of your scales for finer control.
*   Added a new command **/pawn backup** that you can use to back up all of your custom scales at once as a big mass of scale tags.
*   Item levels will now only appear on items in the Compare tab if you also have them enabled for item tooltips in Interface Options.
*   If you hold down the Shift key when clicking the Delete button to delete a scale, the scale will now be deleted immediately without requiring confirmation.
*   Many bugs were fixed, including several bugs that only existed in pre-release versions of Pawn 1.3 and are not listed here:
    *   Fixed a potential error when setting up default Pawn keybindings when using Pawn for the first time for a character, and added a diagnostic message to help determine why the problem is occurring.
    *   Fixed a bug where often the first item comparison you performed in the Compare tab wouldn't show item values until you clicked the Swap button or the list of scales.
    *   Fixed the error that would occur when trying to put an heirloom item in the Compare tab.
    *   Fixed a display issue where scales with colons (':') in their names would appear incorrectly on tooltips if the "align values to right edge of tooltip" option were enabled.
    *   Fixed a bug where the scale total values listed when hovering over a Pawn button on someone's character sheet weren't listed in alphabetical order.

### Older versions

*   See the [version history](Version%20history.htm) document for information about older versions of Pawn.

Known issues and bugs
---------------------

See the [version history](Version%20history.htm) document for information about known issues and bugs.

Future versions
---------------

See the [version history](Version%20history.htm) document for a list of some of the features I'm considering for future versions of Pawn.

The fine print
--------------

© 2006-2010 Green Eclipse.  This mod is released under the Creative Commons [Attribution-NonCommercial-NoDerivs 3.0](http://creativecommons.org/licenses/by-nc-nd/3.0/) license.  In short, this means that you can use it, copy it, and share it, but you can't sell it or distribute your own altered versions without permission. By using the mod you agree to the terms of the license. For more information, click the link.
