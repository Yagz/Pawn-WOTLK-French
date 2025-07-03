-- Pawn by Vger-Azjol-Nerub
-- www.vgermods.com
-- © 2006-2010 Green Eclipse.  This mod is released under the Creative Commons Attribution-NonCommercial-NoDerivs 3.0 license.
-- See Readme.htm for more information.

-- 
-- French resources
------------------------------------------------------------


------------------------------------------------------------
-- "Constants"
------------------------------------------------------------

PawnQuestionTexture = "|TInterface\\AddOns\\Pawn\\Textures\\Question:0|t" -- Texture string that represents a (?).  Don't need to localize this.
PawnUINoScale = "(aucune)" -- The name that shows up in lists of scales if you have no scales

------------------------------------------------------------
-- Master table of stats
------------------------------------------------------------

-- The master list of all stats that Pawn supports.
-- First column is the friendly translated name of the stat.
-- Second column is the Pawn name of the stat; this can't be translated.
-- Third column is the description of the stat.
-- Fourth column is true if the stat can't be ignored.
-- Fifth column is an optional chunk of text instead of the "1 ___ is worth:" prompt.
-- If only a name is present, the row becomes an uneditable header in the UI and is otherwise ignored.
PawnStats =
{
	{"Statistiques de base"},
	{"Force", "Strength", "La statistique principale : Force."},
	{"Agilité", "Agility", "La statistique principale : Agilité."},
	{"Endurance", "Stamina", "La statistique principale : Endurance."},
	{"Intelligence", "Intellect", "La statistique principale : Intelligence."},
	{"Esprit", "Spirit", "La statistique principale : Esprit."},

	{"Châsses"},
	{"Châsse rouge", "RedSocket", "Une châsse rouge vide. Compte uniquement pour la valeur de base de l'objet.", true},
	{"Châsse jaune", "YellowSocket", "Une châsse jaune vide. Compte uniquement pour la valeur de base de l'objet.", true},
	{"Châsse bleue", "BlueSocket", "Une châsse bleue vide. Compte uniquement pour la valeur de base de l'objet.", true},
	{"Méta : stats", "MetaSocket", "Une châsse méta vide. Seul le bonus de statistiques du joyau méta est compté, pas son effet supplémentaire. La valeur de l'objet reste la même, que les conditions soient remplies ou non.", true},
	{"Méta : effet", "MetaSocketEffect", "Une châsse méta, vide ou remplie. Seul l'effet supplémentaire du joyau méta est compté, pas son bonus de statistiques.", true},

	{"Statistiques d'arme"},
	{"DPS", "Dps", "Dégâts par seconde de l'arme."},
	{"Vitesse", "Speed", "Vitesse de l'arme, en secondes par attaque. (Si vous préférez les armes rapides, cette valeur doit être négative.)"},

	{"Scores hybrides"},
	{"Score de toucher", "HitRating", "Score de toucher. Affecte les attaques de mêlée, à distance et les sorts."},
	{"Score de critique", "CritRating", "Score de coup critique. Affecte les attaques de mêlée, à distance et les sorts."},
	{"Score de hâte", "HasteRating", "Score de hâte. Affecte les attaques de mêlée, à distance et les sorts."},
	{"Score de maîtrise", "MasteryRating", VgerCore.Color.Salmon .. "Nouvelle statistique de Cataclysm. " .. VgerCore.Color.Reset .. "Améliore le bonus unique de l’arbre de talents dans lequel vous avez le plus de points."},

	{"Statistiques physiques offensives"},
	{"Puissance d'attaque", "Ap", "Puissance d'attaque. N'inclut pas celle reçue via la Force, l’Agilité ou les DPS d’arme (pour les druides)."},
	{"PA à distance", "Rap", "Puissance d'attaque à distance."},
	{"PA farouche", "FeralAp", "Puissance d’attaque octroyée par une arme en forme farouche (druide). À ne pas combiner avec les DPS d’arme."},
	{"Score d'expertise", "ExpertiseRating", "Score d’expertise."},
	{"Pénétration d’armure", "ArmorPenetration", "La pénétration d’armure permet d’ignorer une partie de l’armure de l’adversaire.\n\n" .. VgerCore.Color.Salmon .. "Cataclysm : " .. VgerCore.Color.Reset .. "Les objets avec pénétration d’armure auront d’autres statistiques offensives."},

	{"Statistiques de sorts"},
	{"Puissance des sorts", "SpellPower", "Puissance des sorts : augmente les dégâts et les soins des sorts."},
	{"Mana toutes les 5 sec", "Mp5", "Régénération de mana toutes les 5 secondes.\n\n" .. VgerCore.Color.Salmon .. "Cataclysm : " .. VgerCore.Color.Reset .. "1 MP5 sera remplacé par 2 Esprit."},
	{"Pénétration des sorts", "SpellPenetration", "Permet à vos sorts d’ignorer une partie des résistances de votre cible."},

	{"Statistiques défensives"},
	{"Armure", "Armor", "Armure, peu importe le type d'objet. Les classes avec des talents augmentant l’armure doivent utiliser l’armure de base et bonus."},
	{"Armure : base", "BaseArmor", "Valeur d’armure de base (tissu, cuir, mailles, plaques). Peut être augmentée par des talents/compétences."},
	{"Armure : bonus", "BonusArmor", "Valeur d’armure bonus (armes, bijoux, anneaux). Non affectée par les talents."},
	{"Valeur de blocage", "BlockValue", "Augmente les dégâts absorbés à chaque blocage réussi.\n\n" .. VgerCore.Color.Salmon .. "Cataclysm : " .. VgerCore.Color.Reset .. "Remplacé par d'autres statistiques de tank."},
	{"Score de blocage", "BlockRating", "Augmente vos chances de bloquer avec un bouclier."},
	{"Score de défense", "DefenseRating", "Score de défense.\n\n" .. VgerCore.Color.Salmon .. "Cataclysm : " .. VgerCore.Color.Reset .. "Remplacé par d'autres statistiques de tank."},
	{"Score d’esquive", "DodgeRating", "Score d’esquive."},
	{"Score de parade", "ParryRating", "Score de parade."},
	{"Score de résilience", "ResilienceRating", "Score de résilience."},

	{"Statistiques très rares"},
	{"Puissance des sorts de feu", "FireSpellDamage", "Puissance des sorts uniquement pour le feu."},
	{"Puissance des sorts d’ombre", "ShadowSpellDamage", "Puissance des sorts uniquement pour l’ombre."},
	{"Puissance des sorts de nature", "NatureSpellDamage", "Puissance des sorts uniquement pour la nature."},
	{"Puissance des sorts des arcanes", "ArcaneSpellDamage", "Puissance des sorts uniquement pour les arcanes."},
	{"Puissance des sorts de givre", "FrostSpellDamage", "Puissance des sorts uniquement pour le givre."},
	{"Puissance des sorts sacrés", "HolySpellDamage", "Puissance des sorts uniquement pour le sacré."},
	{"Toutes résistances", "AllResist", "Toutes les résistances élémentaires."},
	{"Résistance au feu", "FireResist", "Résistance au feu uniquement."},
	{"Résistance à l’ombre", "ShadowResist", "Résistance à l’ombre uniquement."},
	{"Résistance à la nature", "NatureResist", "Résistance à la nature uniquement."},
	{"Résistance aux arcanes", "ArcaneResist", "Résistance aux arcanes uniquement."},
	{"Résistance au givre", "FrostResist", "Résistance au givre uniquement."},
	{"Vie toutes les 5 sec", "Hp5", "Régénération de vie toutes les 5 secondes."},
	{"Vie", "Health", "Vie brute. N’inclut pas celle provenant de l’Endurance."},
	{"Mana", "Mana", "Mana brut. N’inclut pas celui provenant de l’Intelligence."},

	{"Types d’armes"},
	{"Hache : 1M", "IsAxe", "Points à attribuer si c’est une hache à une main."},
	{"Hache : 2M", "Is2HAxe", "Points à attribuer si c’est une hache à deux mains."},
	{"Arc", "IsBow", "Points à attribuer si c’est un arc (ou des flèches)."},
	{"Arbalète", "IsCrossbow", "Points à attribuer si c’est une arbalète."},
	{"Dague", "IsDagger", "Points à attribuer si c’est une dague."},
	{"Arme de pugilat", "IsFist", "Points à attribuer si c’est une arme de pugilat."},
	{"Fusil", "IsGun", "Points à attribuer si c’est un fusil (ou des balles)."},
	{"Masse : 1M", "IsMace", "Points à attribuer si c’est une masse à une main."},
	{"Masse : 2M", "Is2HMace", "Points à attribuer si c’est une masse à deux mains."},
	{"Hallebarde", "IsPolearm", "Points à attribuer si c’est une hallebarde."},
	{"Bâton", "IsStaff", "Points à attribuer si c’est un bâton."},
	{"Épée : 1M", "IsSword", "Points à attribuer si c’est une épée à une main."},
	{"Épée : 2M", "Is2HSword", "Points à attribuer si c’est une épée à deux mains."},
	{"Arme de jet", "IsThrown", "Points à attribuer si c’est une arme de jet."},
	{"Baguette", "IsWand", "Points à attribuer si c’est une baguette."},

	{"Types d’armures"},
	{"Tissu", "IsCloth", "Points à attribuer si c’est une armure en tissu."},
	{"Cuir", "IsLeather", "Points à attribuer si c’est une armure en cuir."},
	{"Mailles", "IsMail", "Points à attribuer si c’est une armure en mailles."},
	{"Plaques", "IsPlate", "Points à attribuer si c’est une armure en plaques."},
	{"Bouclier", "IsShield", "Points à attribuer si c’est un bouclier."},

	{"Statistiques spéciales d’armes"},
	{"Dégâts minimum", "MinDamage", "Dégâts minimum de l’arme."},
	{"Dégâts maximum", "MaxDamage", "Dégâts maximum de l’arme."},
	{"Mêlée : DPS", "MeleeDps", "Dégâts par seconde (mêlée uniquement)."},
	{"Mêlée : dégâts min", "MeleeMinDamage", "Dégâts minimum (mêlée uniquement)."},
	{"Mêlée : dégâts max", "MeleeMaxDamage", "Dégâts maximum (mêlée uniquement)."},
	{"Mêlée : vitesse", "MeleeSpeed", "Vitesse de l’arme (mêlée uniquement)."},
	{"Distance : DPS", "RangedDps", "Dégâts par seconde (à distance uniquement)."},
	{"Distance : dégâts min", "RangedMinDamage", "Dégâts minimum (à distance uniquement)."},
	{"Distance : dégâts max", "RangedMaxDamage", "Dégâts maximum (à distance uniquement)."},
	{"Distance : vitesse", "RangedSped", "Vitesse de l’arme (à distance uniquement)."},
	{"Main principale : DPS", "MainHandDps", "DPS en main principale uniquement."},
	{"Main principale : dégâts min", "MainHandMinDamage", "Dégâts minimum en main principale."},
	{"Main principale : dégâts max", "MainHandMaxDamage", "Dégâts maximum en main principale."},
	{"Main principale : vitesse", "MainHandSpeed", "Vitesse en main principale."},
	{"Main gauche : DPS", "OffHandDps", "DPS en main gauche uniquement."},
	{"Main gauche : dégâts min", "OffHandMinDamage", "Dégâts minimum en main gauche."},
	{"Main gauche : dégâts max", "OffHandMaxDamage", "Dégâts maximum en main gauche."},
	{"Main gauche : vitesse", "OffHandSpeed", "Vitesse en main gauche."},
	{"1M : DPS", "OneHandDps", "DPS pour armes à une main (hors main principale ou gauche)."},
	{"1M : dégâts min", "OneHandMinDamage", "Dégâts minimum pour armes 1M."},
	{"1M : dégâts max", "OneHandMaxDamage", "Dégâts maximum pour armes 1M."},
	{"1M : vitesse", "OneHandSpeed", "Vitesse pour armes 1M."},
	{"2M : DPS", "TwoHandDps", "DPS pour armes à deux mains."},
	{"2M : dégâts min", "TwoHandMinDamage", "Dégâts minimum pour armes 2M."},
	{"2M : dégâts max", "TwoHandMaxDamage", "Dégâts maximum pour armes 2M."},
	{"2M : vitesse", "TwoHandSpeed", "Vitesse pour armes 2M."},
	{"Référence vitesse", "SpeedBaseline", "Pas une statistique réelle. Cette valeur est soustraite de la vitesse avant application du score.", true, "|cffffffffRéférence de vitesse|r :"},
}


------------------------------------------------------------
-- UI strings
------------------------------------------------------------

-- Translation note: All of the strings ending in _Text should be translated; those will show up in the UI.  The strings ending
-- in _Tooltip are only used in tooltips, and can be safely left out.  If you don't want to translate them right now, delete those
-- lines or set them to nil, and Pawn won't show tooltips for those UI elements.


-- Configuration UI
PawnUIFrame_CloseButton_Text = "Fermer"

PawnUIHeaders = {
	"Gérer vos échelles Pawn",             -- Onglet Échelle
	"Valeurs d’échelle pour %s",          -- Onglet Valeurs
	"Comparer les objets avec %s",        -- Onglet Comparer
	"Gemmes pour %s",                     -- Onglet Gemmes
	"Ajuster les options de Pawn",        -- Onglet Options
	"À propos de Pawn",                   -- Onglet À propos
	"Bienvenue sur Pawn !",               -- Onglet Premiers pas
}

-- Configuration UI, Scale selector
PawnUIFrame_ScaleSelector_Header_Text = "Sélectionner une échelle :"

-- Configuration UI, Scale tab (this is a new tab; the old Scales tab is now the Values tab)
PawnUIFrame_ScalesTab_Text = "Échelle"

PawnUIFrame_ScalesWelcomeLabel_Text = "Les échelles sont des ensembles de statistiques et de valeurs utilisées pour attribuer des points aux objets. Vous pouvez créer les vôtres ou utiliser celles d'autres joueurs."

PawnUIFrame_ShowScaleCheck_Label_Text = "Afficher l’échelle dans les info‑bulles"
PawnUIFrame_ShowScaleCheck_Tooltip = "Quand cette option est activée, les valeurs de cette échelle s’afficheront dans les info‑bulles d’objet pour ce personnage. Chaque échelle peut être activée pour un ou plusieurs personnages, ou désactivée."
PawnUIFrame_RenameScaleButton_Text = "Renommer"
PawnUIFrame_RenameScaleButton_Tooltip = "Renommer cette échelle."
PawnUIFrame_DeleteScaleButton_Text = "Supprimer"
PawnUIFrame_DeleteScaleButton_Tooltip = "Supprimer cette échelle.\n\nCette action est irréversible !"
PawnUIFrame_ScaleColorSwatch_Label_Text = "Changer la couleur"
PawnUIFrame_ScaleColorSwatch_Tooltip = "Modifier la couleur utilisée pour afficher le nom et la valeur de cette échelle dans les info‑bulles."
PawnUIFrame_ScaleTypeLabel_NormalScaleText = "Vous pouvez modifier cette échelle dans l’onglet Valeurs."
PawnUIFrame_ScaleTypeLabel_ReadOnlyScaleText = "Vous devez faire une copie de cette échelle pour la personnaliser."

PawnUIFrame_ScaleSettingsShareHeader_Text = "Partager vos échelles"

PawnUIFrame_ImportScaleButton_Text = "Importer"
PawnUIFrame_ImportScaleButton_Label_Text = "Ajouter une nouvelle échelle en collant une balise d’échelle depuis Internet."
PawnUIFrame_ExportScaleButton_Text = "Exporter"
PawnUIFrame_ExportScaleButton_Label_Text = "Partager votre échelle sur Internet."

PawnUIFrame_ScaleSettingsNewHeader_Text = "Créer une nouvelle échelle"

PawnUIFrame_CopyScaleButton_Text = "Copier"
PawnUIFrame_CopyScaleButton_Label_Text = "Créer une échelle en copiant celle-ci."
PawnUIFrame_NewScaleButton_Text = "Vide"
PawnUIFrame_NewScaleButton_Label_Text = "Créer une échelle à partir de zéro."
PawnUIFrame_NewScaleFromDefaultsButton_Text = "Par défaut"
PawnUIFrame_NewScaleFromDefaultsButton_Label_Text = "Copier l’échelle par défaut."

-- Configuration UI, Values tab (previously the Scales tab)
PawnUIFrame_ValuesTab_Text = "Valeurs"

PawnUIFrame_ValuesWelcomeLabel_NormalText = "Personnalisez les valeurs attribuées à chaque statistique pour cette échelle. Pour gérer vos échelles, utilisez l’onglet Échelle."
PawnUIFrame_ValuesWelcomeLabel_NoScalesText = "Aucune échelle sélectionnée. Allez dans l’onglet Échelle pour créer ou coller une échelle."
PawnUIFrame_ValuesWelcomeLabel_ReadOnlyScaleText = "Cette échelle est en lecture seule. Copiez-la ou créez-en une nouvelle pour la modifier."

PawnUIFrame_ClearValueButton_Text = "Retirer"
PawnUIFrame_ClearValueButton_Tooltip = "Retirer cette statistique de l’échelle."

PawnUIFrame_IgnoreStatCheck_Text = "Objets avec cette stat inutilisables"
PawnUIFrame_IgnoreStatCheck_Tooltip = "Activez cette option pour que tout objet contenant cette statistique ne reçoive pas de valeur pour cette échelle."

PawnUIFrame_ScaleSocketOptionsHeaderLabel_Text = "Lors du calcul d’une valeur pour cette échelle :"
PawnUIFrame_ScaleSocketBestRadio_Text = "Gérer automatiquement les châsses"
PawnUIFrame_ScaleSocketBestRadio_Tooltip = "Pawn calcule la valeur en supposant que vous placerez les gemmes optimales."
PawnUIFrame_ScaleSocketCorrectRadio_Text = "Définir manuellement la valeur des châsses"
PawnUIFrame_ScaleSocketCorrectRadio_Tooltip = "Pawn utilisera la valeur des châsses que vous spécifiez."

PawnUIFrame_NormalizeValuesCheck_Text = "Normaliser les valeurs (comme Wowhead)"
PawnUIFrame_NormalizeValuesCheck_Tooltip = "Diviser la valeur totale par la somme des valeurs statistiques de l’échelle, pour garder les chiffres petits et comparables.\n\nVoir le readme pour plus de détails."

-- Configuration UI, Compare tab
PawnUIFrame_CompareTab_Text = "Comparer"

PawnUIFrame_VersusHeader_Text = "—vs.—"
PawnUIFrame_VersusHeader_NoItem = "(aucun objet)"

PawnUIFrame_CompareMissingItemInfo_TextLeft = "D’abord, sélectionnez une échelle à gauche."
PawnUIFrame_CompareMissingItemInfo_TextRight = "Puis, glissez un objet ici.\n\nPawn le comparera à l’objet équipé."

PawnUIFrame_CompareSocketBonusHeader_Text = "Bonus de châsse"

PawnUIFrame_CompareOtherInfoHeader_Text = "Autres"
PawnUIFrame_CompareAsterisk = "Effets spéciaux " .. PawnQuestionTexture
PawnUIFrame_CompareAsterisk_Yes = "Oui"

PawnUIFrame_CurrentCompareScaleDropDown_Label_Text = "Échelle de comparaison"
PawnUIFrame_CurrentCompareScaleDropDown_Tooltip = "Choisissez l’échelle utilisée pour la comparaison."

PawnUIFrame_ClearItemsButton_Label = "Effacer"
PawnUIFrame_ClearItemsButton_Tooltip = "Retirer les deux objets."

PawnUIFrame_CompareSwapButton_Text = "< Échanger >"
PawnUIFrame_CompareSwapButton_Tooltip = "Permuter les objets gauche/droite."

-- Configuration UI, Gems tab
PawnUIFrame_GemsTab_Text = "Gemmes"
PawnUIFrame_GemsHeaderLabel_Text = "Choisissez une échelle pour que Pawn détermine les meilleures gemmes."

PawnUIFrame_CurrentGemsScaleDropDown_Label_Text = "Gemmes optimales pour :"
PawnUIFrame_CurrentGemsScaleDropDown_Tooltip = "Sélectionnez une échelle pour le calcul des gemmes."

PawnUIFrame_GemQualityDropDown_Label_Text = "Qualité :"
PawnUIFrame_GemQualityDropDown_Tooltip = "Choisissez la qualité des gemmes considérées."

PawnUIFrame_FindGemColorHeader_Text = "Gemmes %s"
PawnUIFrame_FindGemColorHeader_Meta_Text = "Gemmes méta (effets ignorés)"
PawnUIFrame_FindGemNoGemsHeader_Text = "Aucune gemme trouvée."

-- Configuration UI, Options tab
PawnUIFrame_OptionsTab_Text = "Options"
PawnUIFrame_OptionsHeaderLabel_Text = "Configurez Pawn selon vos préférences. Les changements sont instantanés."

PawnUIFrame_TooltipOptionsHeaderLabel_Text = "Options des info‑bulles"
PawnUIFrame_ShowItemLevelsCheck_Text = "Afficher les niveaux d’objet"
PawnUIFrame_ShowItemLevelsCheck_Tooltip = "Afficher le niveau caché de l’objet dans les info‑bulles."
PawnUIFrame_ShowItemIDsCheck_Text = "Afficher les IDs d’objet"
PawnUIFrame_ShowItemIDsCheck_Tooltip = "Afficher les IDs d’objet, enchantements et gemmes (utile pour les auteurs d’addons)."
PawnUIFrame_ShowIconsCheck_Text = "Afficher les icônes d’inventaire"
PawnUIFrame_ShowIconsCheck_Tooltip = "Montrer les icônes d’objet à côté des liens."
PawnUIFrame_ShowExtraSpaceCheck_Text = "Ajouter une ligne vide avant les valeurs"
PawnUIFrame_ShowExtraSpaceCheck_Tooltip = "Ajoute un espace avant les valeurs Pawn pour une présentation plus claire."
PawnUIFrame_AlignRightCheck_Text = "Aligner les valeurs à droite de l’info‑bulle"
PawnUIFrame_AlignRightCheck_Tooltip = "Aligne les valeurs Pawn (et niveaux/IDs) à droite de l’info‑bulles."
PawnUIFrame_AsterisksHeaderLabel_Text = "Afficher " .. PawnQuestionTexture .. " sur effets spéciaux :"
PawnUIFrame_AsterisksAutoRadio_Text = "Activé"
PawnUIFrame_AsterisksAutoRadio_Tooltip = "Afficher l’icône " .. PawnQuestionTexture .. " sur les objets avec effets spéciaux."
PawnUIFrame_AsterisksAutoNoTextRadio_Text = "Activé, sans message"
PawnUIFrame_AsterisksAutoNoTextRadio_Tooltip = "Afficher l’icône sans message d’avertissement."
PawnUIFrame_AsterisksOffRadio_Text = "Désactivé" 
PawnUIFrame_AsterisksOffRadio_Tooltip = "Ne pas afficher l’icône " .. PawnQuestionTexture .. " ni d’avertissement."

PawnUIFrame_CalculationOptionsHeaderLabel_Text = "Options de calcul"
PawnUIFrame_DigitsBox_Label_Text = "Décimales de précision :"
PawnUIFrame_DigitsBox_Tooltip = "Nombre de décimales affichées dans les valeurs Pawn (0–9)."
PawnUIFrame_UnenchantedValuesCheck_Text = "Afficher les valeurs brutes"
PawnUIFrame_UnenchantedValuesCheck_Tooltip = "Afficher les valeurs des objets sans enchantement ou gemmes."
PawnUIFrame_EnchantedValuesCheck_Text = "Afficher les valeurs actuelles"
PawnUIFrame_EnchantedValuesCheck_Tooltip = "Afficher les valeurs avec enchantements et gemmes."
PawnUIFrame_DebugCheck_Text = "Afficher les infos de débogage"
PawnUIFrame_DebugCheck_Tooltip = "Activer pour afficher comment Pawn calcule les valeurs dans le chat.\n\nRapide à remplir le chat, donc désactivez ensuite."

PawnUIFrame_OtherOptionsHeaderLabel_Text = "Autres options"
PawnUIFrame_ButtonPositionHeaderLabel_Text = "Afficher le bouton Pawn :"
PawnUIFrame_ButtonRightRadio_Text = "En bas à droite"
PawnUIFrame_ButtonRightRadio_Tooltip = "Afficher le bouton dans le coin inférieur droit du panneau de personnage."
PawnUIFrame_ButtonLeftRadio_Text = "En bas à gauche"
PawnUIFrame_ButtonLeftRadio_Tooltip = "Afficher le bouton dans le coin inférieur gauche du panneau de personnage."
PawnUIFrame_ButtonOffRadio_Text = "Le cacher"
PawnUIFrame_ButtonOffRadio_Tooltip = "Ne pas afficher le bouton Pawn."

-- Configuration UI, About tab
PawnUIFrame_AboutTab_Text = "À propos"
PawnUIFrame_AboutHeaderLabel_Text = "par Vger‑Azjol‑Nerub – Mis à jour par Undeadhunter"
PawnUIFrame_AboutVersionLabel_Text = "Version %s – Chomiecraft par Undeadhunter"
PawnUIFrame_AboutTranslationLabel_Text = "Version française "
PawnUIFrame_ReadmeLabel_Text = "Nouveau sur Pawn ? Consultez l’onglet Premiers pas pour commencer. Le readme détaille les fonctionnalités avancées."
PawnUIFrame_WebsiteLabel_Text = "Pour d'autres mods de Vger, rendez-vous sur vgermods.com.\n\nValeurs de Wowhead utilisées avec autorisation. Pour retours, visitez les forums de théorie de Wowhead."

-- Configuration UI, Help tab
PawnUIFrame_HelpTab_Text = "Démarrage"
PawnUIFrame_GettingStartedLabel_Text =
	"Pawn calcule un score pour les objets afin de vous aider à voir rapidement lequel est le meilleur. Ces scores s’affichent dans les info‑bulles.\n\n\n" ..
	"Chaque objet reçoit plusieurs scores : un pour chaque échelle active. Une échelle liste les stats importantes et leur valeur." ..
	"\n\n\nPawn inclut des échelles Wowhead pour chaque classe et spé. Vous pouvez les activer, en créer, ou partager les vôtres.\n\n\n" ..
	VgerCore.Color.Blue .. "Testez ceci une fois les bases apprises :\n" .. VgerCore.Color.Reset ..
	" • Comparer deux objets dans l’onglet Comparer.\n" ..
	" • Clic droit sur un lien d’objet pour comparer avec l’équipé.\n" ..
	" • Maj+clic droit sur un objet à châsses pour des suggestions de gemmes.\n" ..
	" • Dupliquez une échelle puis personnalisez-la.\n" ..
	" • Trouvez plus d’échelles en ligne ou construisez-les avec Rawr.\n" ..
	" • Consultez le readme pour les fonctionnalités avancées."

-- Inventory button
PawnUI_InventoryPawnButton_Tooltip = "Cliquez pour afficher l’interface Pawn."
PawnUI_InventoryPawnButton_Subheader = "Total pour tous les objets équipés :"

-- Socketing button
PawnUI_SocketingPawnButton_Tooltip = "Cliquez pour afficher l’interface de gemmes Pawn."

-- Item socketing UI
PawnUI_ItemSocketingDescription_Header = "Pawn suggère ces gemmes :"

-- Interface Options page
PawnInterfaceOptionsFrame_OptionsHeaderLabel_Text = "Options Pawn disponibles dans l’interface Pawn."
PawnInterfaceOptionsFrame_OptionsSubHeaderLabel_Text = "Cliquez sur le bouton Pawn pour accéder à ses options, ou utilisez l’inventaire ou un raccourci."

-- Bindings UI
BINDING_HEADER_PAWN = "Pawn"
BINDING_NAME_PAWN_TOGGLE_UI = "Afficher/cacher l’interface Pawn"
PAWN_TOGGLE_UI_DEFAULT_KEY = "P"
BINDING_NAME_PAWN_COMPARE_LEFT = "Comparer objet (gauche)"
PAWN_COMPARE_LEFT_DEFAULT_KEY = "["
BINDING_NAME_PAWN_COMPARE_RIGHT = "Comparer objet (droite)"
PAWN_COMPARE_RIGHT_DEFAULT_KEY = "]"


PawnLocal =
{

	-- General messages
	["NeedNewerVgerCoreMessage"] = "Pawn a besoin d'une version plus récente de VgerCore. Veuillez utiliser la version de VgerCore fournie avec Pawn.",
	
	-- Scale management dialog messages
	["NewScaleEnterName"] = "Entrez un nom pour votre évaluation :",
	["NewScaleNoQuotes"] = "Une évaluation ne peut pas avoir \" dans son nom. Entrez un nom pour votre évaluation :",
	["NewScaleDuplicateName"] = "Une évaluation avec ce nom existe déjà. Entrez un nom pour votre évaluation :",
	
	["CopyScaleEnterName"] = "Entrez un nom pour votre nouvelle évaluation, une copie de %s :", -- %s is the name of the existing scale
	["RenameScaleEnterName"] = "Entrez un nouveau nom pour %s :", -- %s is the old name of the scale
	["DeleteScaleConfirmation"] = "Êtes-vous sûr de vouloir supprimer %s ? Cette action ne peut pas être annulée. Tapez \"%s\" pour confirmer :", -- First %s is the name of the scale, second %s is DELETE
	
	["ImportScaleMessage"] = "Appuyez sur Ctrl+V pour coller ici une chaîne d'évaluation que vous avez copiée depuis une autre source :",
	["ImportScaleTagErrorMessage"] = "Pawn ne comprend pas cette chaîne d'évaluation. Avez-vous copié la chaîne entière ? Essayez de copier et coller à nouveau :",
	
	["ExportScaleMessage"] = "Appuyez sur Ctrl+C pour copier la chaîne d'évaluation suivante pour |cffffffff%s|r, puis appuyez sur Ctrl+V pour la coller plus tard.", -- %s is name of scale
	["ExportAllScalesMessage"] = "Appuyez sur Ctrl+C pour copier vos chaînes d'évaluation, créez un fichier sur votre ordinateur pour les sauvegarder, puis appuyez sur Ctrl+V pour les coller.",
	
	-- Scale selector
	["VisibleScalesHeader"] = "Évaluations de %s", -- %s is name of character
	["HiddenScalesHeader"] = "Autres évaluations",
	
	-- Configuration UI, Values tab
	["Unusable"] = "(inutilisable)",
	["NoStatDescription"] = "Choisissez une statistique dans la liste de gauche.",
	["NoScalesDescription"] = "Pour commencer, importez une évaluation ou créez-en une nouvelle.",
	["StatNameText"] = "1 |cffffffff%s|r vaut :", -- |cffffffff%s|r is the name of the stat, in white
	
	-- Generic string dialogs
	["OKButton"] = "OK",
	["CancelButton"] = "Annuler",
	["CloseButton"] = "Fermer",
	
	-- Debug messages
	["EnchantedStatsHeader"] = "(Valeur actuelle)",
	["UnenchantedStatsHeader"] = "(Valeur de base)",
	["FailedToGetItemLinkMessage"] = "   Impossible d'obtenir le lien d'objet depuis l'infobulle. Cela peut être dû à un conflit de mod.",
	["FailedToGetUnenchantedItemMessage"] = "   Impossible d'obtenir les valeurs d'objet de base. Cela peut être dû à un conflit de mod.",
	["DidntUnderstandMessage"] = "   (?) N'a pas compris \"%s\".",
	["FoundStatMessage"] = "   %d %s", -- 25 Stamina
	
	["ValueCalculationMessage"] = "   %g %s x %g chacun = %g", -- 25 Stamina x 1 each = 25
	["UnusableStatMessage"] = "   -- %s est inutilisable, donc arrêt.", -- IsPlate is unusable, so stopping
	["SocketBonusValueCalculationMessage"] = "   -- Le bonus de châsse vaudrait :",
	["MissocketWorthwhileMessage"] = "   -- Mais il vaut mieux utiliser seulement des gemmes %s :", -- Better to use only Red/Blue gems:
	["NormalizationMessage"] = "   ---- Normalisé en divisant par %g", -- Normalized by dividing by 3.5
	["TotalValueMessage"] = "   ---- Total : %g", -- Total: 25
	
	-- Tooltip annotations
	["ItemIDTooltipLine"] = "ID d'objet",
	["ItemLevelTooltipLine"] = "Niveau d'objet",
	["AverageItemLevelTooltipLine"] = "Niveau d'équipement épique",
	["BaseValueWord"] = "base", -- 123.45 (98.76 base)
	["AsteriskTooltipLine"] = "|TInterface\\AddOns\\Pawn\\Textures\\Question:0|t Effets spéciaux non inclus dans la valeur.",
	
	-- Gem stuff
	["GenericGemName"] = "(Gemme %d)", -- (Gemme 12345)
	["GenericGemLink"] = "|Hitem:%d|h[Gemme %d]|h", -- [Gemme 12345]
	["GemColorList1"] = "%d %s", -- 2 Rouge
	["GemColorList2"] = "%d %s ou %s", -- 3 Rouge ou Jaune
	["GemColorList3"] = "%d de n'importe quelle couleur", -- 1 de n'importe quelle couleur

	["PawnGemData70Uncommon"] = "Niveau 70 peu commun",	
	["PawnGemData70Rare"] = "Niveau 70 rare",	
	["PawnGemData70Epic"] = "Niveau 70 épique",	
	["MetaGemQualityLevel70Rare"] = "Niveau 70 fabriqué",

	["GemQualityLevel80Uncommon"] = "Niveau 80 peu commun",
	["GemQualityLevel80Rare"] = "Niveau 80 rare",
	["GemQualityLevel80Epic"] = "Niveau 80 épique",
	["MetaGemQualityLevel80Rare"] = "Niveau 80 fabriqué",
	["GemQualityLevel85Uncommon"] = "Niveau 85 peu commun",
	["GemQualityLevel85Rare"] = "Niveau 85 rare",
	["GemQualityLevel85Epic"] = "Niveau 85 épique",
	["MetaGemQualityLevel85Rare"] = "Niveau 85 fabriqué",
	
	-- Slash commands
	["DebugOnCommand"] = "debug on",
	["DebugOffCommand"] = "debug off",
	["BackupCommand"] = "backup",
	
	["Usage"] = [[
Pawn par Vger-Azjol-Nerub
www.vgermods.com
 
/pawn -- afficher ou masquer l'interface de Pawn
/pawn debug [ on | off ] -- afficher les messages de débogage dans la console
/pawn backup -- sauvegarder toutes vos évaluations
 
Pour plus d'informations sur la personnalisation de Pawn, consultez le fichier d'aide (Readme.htm) fourni avec le mod.
]],

}


------------------------------------------------------------
-- Localized scale names
------------------------------------------------------------

PawnWowheadScale_Provider = "Évaluations Wowhead"
PawnWowheadScale_WarriorArms = "Guerrier : armes"
PawnWowheadScale_WarriorFury = "Guerrier : fureur"
PawnWowheadScale_WarriorTank = "Guerrier : protection"
PawnWowheadScale_PaladinHoly = "Paladin : sacré"
PawnWowheadScale_PaladinTank = "Paladin : protection"
PawnWowheadScale_PaladinRetribution = "Paladin : vindicte"
PawnWowheadScale_HunterBeastMastery = "Chasseur : maîtrise des bêtes"
PawnWowheadScale_HunterMarksman = "Chasseur : précision"
PawnWowheadScale_HunterSurvival = "Chasseur : survie"
PawnWowheadScale_RogueAssassination = "Voleur : assassinat"
PawnWowheadScale_RogueCombat = "Voleur : combat"
PawnWowheadScale_RogueSubtlety = "Voleur : finesse"
PawnWowheadScale_PriestDiscipline = "Prêtre : discipline"
PawnWowheadScale_PriestHoly = "Prêtre : sacré"
PawnWowheadScale_PriestShadow = "Prêtre : ombre"
PawnWowheadScale_DeathKnightBloodDps = "Chevalier de la mort : sang DPS"
PawnWowheadScale_DeathKnightBloodTank = "Chevalier de la mort : sang tank"
PawnWowheadScale_DeathKnightFrostDps = "Chevalier de la mort : givre DPS"
PawnWowheadScale_DeathKnightFrostTank = "Chevalier de la mort : givre tank"
PawnWowheadScale_DeathKnightUnholyDps = "Chevalier de la mort : impie DPS"
PawnWowheadScale_ShamanElemental = "Chaman : élémentaire"
PawnWowheadScale_ShamanEnhancement = "Chaman : amélioration"
PawnWowheadScale_ShamanRestoration = "Chaman : restauration"
PawnWowheadScale_MageArcane = "Mage : arcane"
PawnWowheadScale_MageFire = "Mage : feu"
PawnWowheadScale_MageFrost = "Mage : givre"
PawnWowheadScale_WarlockAffliction = "Démoniste : affliction"
PawnWowheadScale_WarlockDemonology = "Démoniste : démonologie"
PawnWowheadScale_WarlockDestruction = "Démoniste : destruction"
PawnWowheadScale_DruidBalance = "Druide : équilibre"
PawnWowheadScale_DruidFeralDps = "Druide : féral chat"
PawnWowheadScale_DruidFeralTank = "Druide : féral ours"
PawnWowheadScale_DruidRestoration = "Druide : restauration"

------------------------------------------------------------
-- Tooltip parsing expressions
------------------------------------------------------------

-- Turns a game constant into a regular expression.
function PawnGameConstant(Text)
	return "^" .. PawnGameConstantUnwrapped(Text) .. "$"
end
function PawnGameConstantUnwrapped(Text)
	-- REVIEW: This function seems stupid.
	return gsub(gsub(Text, "%%", "%%%%"), "%-", "%%-")
end

-- These strings indicate that a given line might contain multiple stats, such as complex enchantments
-- (ZG, AQ) and gems.  These are sorted in priority order.  If a string earlier in the table is present, any
-- string later in the table can be ignored.
PawnSeparators =
{
	", ",
	"/",
	" & ",
	" et ",
}

-- This string indicates that whatever stats follow it on the same line is the item's socket bonus.
PawnSocketBonusPrefix = "Bonus de châsse : "

-- Lines that match any of the following patterns will cause all further tooltip parsing to stop.
PawnKillLines =
{
	"^ \n$", -- The blank line before set items before WoW 2.3
	" %(%d+/%d+%)$", -- The (1/8) on set items for all versions of WoW
	"^|cff00e0ffLâché par", -- Mod compatibility: MobInfo-2 (should match mifontLightBlue .. MI_TXT_DROPPED_BY)
}

-- Lines that begin with any of the following strings will not be searched for separator strings.
PawnSeparatorIgnorePrefixes =
{
	'"', -- double quote
	"Équiper :",
	"Utiliser :",
	"Chance à l'impact :",
}

-- Items that begin with any of the following strings will never be parsed.
PawnIgnoreNames =
{
	"Concept :",
	"Formule :",
	"Manuel :",
	"Patron :",
	"Plans :",
	"Recette :",
	"Schéma :",
}

-- This is a list of regular expression substitutions that Pawn performs to normalize stat names before running
-- them through the normal gauntlet of expressions.
PawnNormalizationRegexes = {
    -- Normalisation avec caractères UTF-8 propres (plus de texte corrompu)
    {"^([%w%s%.àáâãäçèéêëìíîïðñòóôõöùúûüýÿ]+) %+(%d+)$", "+%2 %1"},
    {"^(.-)|r.*", "%1"},
}

-- These regular expressions are used to parse item tooltips.
-- The first string is the regular expression to match.  Stat values should be denoted with "(%d+)".
-- Subsequent strings follow this pattern: Stat, Number, Source
-- Stat is the name of a statistic.
-- Number is either the amount of that stat to include, or the 1-based index into the matches array produced by the regex.
-- If it's an index, it can also be negative to mean that the stat should be subtracted instead of added.  If nil, defaults to 1.
-- Source is either PawnMultipleStatsFixed if Number is the amount of the stat, or PawnMultipleStatsExtract or nil if Number is the matches array index.
-- Note that certain strings don't need to be translated: for example, the game defines
-- ITEM_BIND_ON_PICKUP to be "Binds when picked up" in English, and the correct string
-- in other languages automatically.
PawnMultipleStatsFixed = "_MultipleFixed"
PawnMultipleStatsExtract = "_MultipleExtract"
PawnRegexes =
{
	-- ========================================
	-- Strings that are ignored for compatibility with other mods
	-- ========================================
	{"^Used by outfits:"}, -- Mod compatibility: Outfitter
	
	-- ========================================
	-- Common strings that are ignored (rare ones are at the bottom of the file)
	-- ========================================
	{PawnGameConstant(ITEM_QUALITY0_DESC)}, -- Poor
	{PawnGameConstant(ITEM_QUALITY1_DESC)}, -- Common
	{PawnGameConstant(ITEM_QUALITY2_DESC)}, -- Uncommon
	{PawnGameConstant(ITEM_QUALITY3_DESC)}, -- Rare
	{PawnGameConstant(ITEM_QUALITY4_DESC)}, -- Epic
	{PawnGameConstant(ITEM_QUALITY5_DESC)}, -- Legendary
	{PawnGameConstant(ITEM_QUALITY7_DESC)}, -- Heirloom
	{PawnGameConstant(ITEM_HEROIC)}, -- Heroic (Thrall's Chestguard of Triumph, level 258 version)
	{PawnGameConstant(ITEM_HEROIC_EPIC)}, -- Heroic Epic (Thrall's Chestguard of Triumph, level 258 version, with colorblind mode on)
	{"^" .. ITEM_LEVEL}, -- Item Level 200
	{PawnGameConstant(ITEM_UNSELLABLE)}, -- No sell price
	{PawnGameConstant(ITEM_SOULBOUND)}, -- Soulbound
	{PawnGameConstant(ITEM_BIND_ON_EQUIP)}, -- Binds when equipped
	{PawnGameConstant(ITEM_BIND_ON_PICKUP)}, -- Binds when picked up
	{PawnGameConstant(ITEM_BIND_ON_USE)}, -- Binds when used
	{PawnGameConstant(ITEM_BIND_TO_ACCOUNT)}, -- Binds to account (Polished Spaulders of Valor)
	{"^" .. PawnGameConstantUnwrapped(ITEM_UNIQUE)}, -- Unique; leave off the $ for Unique(20)
	{"^" .. PawnGameConstantUnwrapped(ITEM_BIND_QUEST)}, -- Leave off the $ for MonkeyQuest mod compatibility
	{PawnGameConstant(ITEM_STARTS_QUEST)}, -- This Item Begins a Quest
	{PawnGameConstant(ITEM_CONJURED)}, -- Conjured Item
	{PawnGameConstant(ITEM_PROSPECTABLE)}, -- Prospectable
	{PawnGameConstant(ITEM_MILLABLE)}, -- Millable
	{PawnGameConstant(ITEM_DISENCHANT_NOT_DISENCHANTABLE)}, -- Cannot be disenchanted
	{"^Will receive"}, -- Appears in the trade window when an item is about to be enchanted ("Will receive +8 Stamina")
	{"^Disenchanting requires"}, -- Appears on item tooltips when the Disenchant ability is specified ("Disenchanting requires Enchanting (25)")
	{PawnGameConstant(ITEM_ENCHANT_DISCLAIMER)}, -- Item will not be traded!
	{"^.+ Charges?$"}, -- Brilliant Mana Oil
	{PawnGameConstant(LOCKED)}, -- Locked
	{PawnGameConstant(ENCRYPTED)}, -- Encrypted (Floral Foundations) (does not seem to exist in the game yet)
	{PawnGameConstant(ITEM_SPELL_KNOWN)}, -- Already Known
	{PawnGameConstant(INVTYPE_HEAD)}, -- Head
	{PawnGameConstant(INVTYPE_NECK)}, -- Neck
	{PawnGameConstant(INVTYPE_SHOULDER)}, -- Shoulder
	{PawnGameConstant(INVTYPE_CLOAK), "IsCloth", 1, PawnMultipleStatsFixed}, -- Back (cloaks are cloth even though they don't list it)
	{PawnGameConstant(INVTYPE_ROBE)}, -- Chest
	{PawnGameConstant(INVTYPE_BODY)}, -- Shirt
	{PawnGameConstant(INVTYPE_TABARD)}, -- Tabard
	{PawnGameConstant(INVTYPE_WRIST)}, -- Wrist
	{PawnGameConstant(INVTYPE_HAND)}, -- Hands
	{PawnGameConstant(INVTYPE_WAIST)}, -- Waist
	{PawnGameConstant(INVTYPE_FEET)}, -- Feet
	{PawnGameConstant(INVTYPE_LEGS)}, -- Legs
	{PawnGameConstant(INVTYPE_FINGER)}, -- Finger
	{PawnGameConstant(INVTYPE_TRINKET)}, -- Trinket
	{PawnGameConstant(MAJOR_GLYPH)}, -- Major Glyph
	{PawnGameConstant(MINOR_GLYPH)}, -- Minor Glyph
	{"^Totem$"},
	{"^Relic$"},
	{"^Idol$"},
	{"^Libram$"},
	{"^Mount$"}, -- Cenarion War Hippogryph
	{"^Classes:"},
	{"^Races:"},
	{"^Requires"},
	{"^Durability"},
	{"^Duration:"},
	{"^Cooldown remaining:"},
	{"<.+>"}, -- Made by, Right-click to read, etc. (No ^$; can be prefixed by a color)
	{"^Written by "},
	{"|cff%x%x%x%x%x%xRequires"}, -- Meta gem requirements
	{"^%d+ Slot .+$"}, -- Bags of all kinds
	{"^.+%(%d+ sec%)$"}, -- Temporary item buff
	{"^.+%(%d+ min%)$"}, -- Temporary item buff
	{"^Enchantment Requires"}, -- Seen on the enchanter-only ring enchantments when you're not an enchanter, and socketed jewelcrafter-only BoP gems
	{"^Niveau (%d+) requis$"},
	{"^Lié quand équipé$"},  
	{"^Lié quand ramassé$"},
	{"^Soulié au compte$"},
	{"^À une main$"},
	{"^Arme à une main$"},
	{"^Unique%-équipé$"},
	{"^Utiliser :"},
	{"^Classes : "},
	{"^Races : "},
	
	-- ========================================
	-- Strings that represent statistics that Pawn cares about
	-- ========================================
	{PawnGameConstant(INVTYPE_RANGED), "IsRanged", 1, PawnMultipleStatsFixed}, -- À distance
	{"^Projectile$", "IsRanged", 1, PawnMultipleStatsFixed}, -- Projectile
	{PawnGameConstant(INVTYPE_THROWN), "IsRanged", 1, PawnMultipleStatsFixed}, -- Arme de jet
	{PawnGameConstant(INVTYPE_WEAPON), "IsOneHand", 1, PawnMultipleStatsFixed}, -- Une main
	{PawnGameConstant(INVTYPE_2HWEAPON), "IsTwoHand", 1, PawnMultipleStatsFixed}, -- Deux mains
	{PawnGameConstant(INVTYPE_WEAPONMAINHAND), "IsMainHand", 1, PawnMultipleStatsFixed}, -- Main principale
	{PawnGameConstant(INVTYPE_WEAPONOFFHAND), "IsOffHand", 1, PawnMultipleStatsFixed}, -- Main secondaire
	{PawnGameConstant(INVTYPE_HOLDABLE)}, -- Tenu en main secondaire ; pas de stat Pawn pour ceci
	{"^(%d-) %- (%d-) Dégâts$", "MinDamage", 1, PawnMultipleStatsExtract, "MaxDamage", 2, PawnMultipleStatsExtract}, -- Arme standard
	{"^Dégâts : (%d+) %- (%d+)$", "MinDamage", 1, PawnMultipleStatsExtract, "MaxDamage", 2, PawnMultipleStatsExtract},
	{"^%+(%d+) aux dégâts de l'arme$", "WeaponDamage"},
	{"^%+?(%d-) %- (%d-) Dégâts de feu$", "MinDamage", 1, PawnMultipleStatsExtract, "MaxDamage", 2, PawnMultipleStatsExtract}, -- Baguette
	{"^%+?(%d-) %- (%d-) Dégâts d'ombre$", "MinDamage", 1, PawnMultipleStatsExtract, "MaxDamage", 2, PawnMultipleStatsExtract}, -- Baguette
	{"^%+?(%d-) %- (%d-) Dégâts de nature$", "MinDamage", 1, PawnMultipleStatsExtract, "MaxDamage", 2, PawnMultipleStatsExtract}, -- Baguette, Thunderfury
	{"^%+?(%d-) %- (%d-) Dégâts des arcanes$", "MinDamage", 1, PawnMultipleStatsExtract, "MaxDamage", 2, PawnMultipleStatsExtract}, -- Baguette
	{"^%+?(%d-) %- (%d-) Dégâts de givre$", "MinDamage", 1, PawnMultipleStatsExtract, "MaxDamage", 2, PawnMultipleStatsExtract}, -- Baguette
	{"^%+?(%d-) %- (%d-) Dégâts du sacré$", "MinDamage", 1, PawnMultipleStatsExtract, "MaxDamage", 2, PawnMultipleStatsExtract}, -- Baguette, Ashbringer
	{"^%+?(%d-) Dégâts d'arme$", "MinDamage", 1, PawnMultipleStatsExtract, "MaxDamage", 1, PawnMultipleStatsExtract}, -- Enchantements d'arme
	{"^Équipé : %+?(%d-) Dégâts d'arme%.$", "MinDamage", 1, PawnMultipleStatsExtract, "MaxDamage", 1, PawnMultipleStatsExtract}, -- Chaîne d'éternium tressée
	{"^%+?(%d-) Dégâts$", "MinDamage", 1, PawnMultipleStatsExtract, "MaxDamage", 1, PawnMultipleStatsExtract}, -- Armes sans portée de dégâts
	{"^Lunette %(%+(%d-) Dégâts%)$", "MinDamage", 1, PawnMultipleStatsExtract, "MaxDamage", 1, PawnMultipleStatsExtract}, -- Lunettes d'armes à distance
	{"^%+?(%d+) à toutes les caractéristiques$", "Strength", 1, PawnMultipleStatsExtract, "Agility", 1, PawnMultipleStatsExtract, "Stamina", 1, PawnMultipleStatsExtract, "Intellect", 1, PawnMultipleStatsExtract, "Spirit", 1, PawnMultipleStatsExtract},
	{"^%+?(%d+) to All Stats$", "Strength", 1, PawnMultipleStatsExtract, "Agility", 1, PawnMultipleStatsExtract, "Stamina", 1, PawnMultipleStatsExtract, "Intellect", 1, PawnMultipleStatsExtract, "Spirit", 1, PawnMultipleStatsExtract}, -- Enchanted Pearl, Enchanted Tear
	{"^%+?(%-?%d+) Force$", "Strength"},
	{"^Puissance$", "Strength", 20, PawnMultipleStatsFixed}, -- enchantement d'arme (non testé)
	{"^%+?(%-?%d+) Agilité$", "Agility"},
	{"^%+(%d+) Agilité$", "Agility"},
	{"^AgilitÃ©$", "Agility", 1, PawnMultipleStatsFixed},
	{"^%+?(%-?%d+) Endurance$", "Stamina"},
	{"^Endurance$", "Stamina", 1, PawnMultipleStatsFixed},
	{"^%+?(%-?%d+) Intelligence$", "Intellect"}, -- Intelligence négative : Chope de Kreeg
	{"^%+(%d+) Intelligence$", "Intellect"},
	{"^Intelligence$", "Intellect", 1, PawnMultipleStatsFixed},
	{"^%+?(%-?%d+) Esprit$", "Spirit"},
	{"^%+(%d+) Esprit$", "Spirit"},
	{"^Chaîne d'arme en titane$", "HitRating", 28, PawnMultipleStatsFixed}, -- Enchantement d'arme ; a des effets supplémentaires
	{"^%+?(%d+) Blocage$", "BlockValue"},
	{"^Bloquer : (%d+)$", "BlockValue"},
	{"^%+(%d+) Valeur de blocage$", "BlockValue"}, -- partie de l'enchantement de casque de guerrier complexe
	{"^%+(%d+) Valeur de blocage du bouclier$", "BlockValue"}, -- Placage de titane
	{"^Équipé : Augmente la valeur de blocage de votre bouclier de (%d+)%.$", "BlockValue"},
	{"^Équipé : Augmente votre score de blocage de (%d+)%.$", "BlockRating"}, -- Ceinture de colère
	{"^Équipé : Augmente votre score de blocage du bouclier de (%d+)%.$", "BlockRating"}, -- Plastron du porteguerre
	{"^%+?(%d+) Score de blocage$", "BlockRating"}, -- Bouclier de blocage du nordique
	{"^%+?(%d+) Score de blocage du bouclier$", "BlockRating"}, -- enchantement
	{"^Équipé : Augmente le score de défense de (%d+)%.$", "DefenseRating"}, -- Rempart des rois
	{"^%+(%d+) au score de défense$", "DefenseRating"},
	{"^Augmente le score de défense de (%d+)%.$", "DefenseRating"},
	{"^Score de défense %+(%d)%$", "DefenseRating"},
	{"^%+?(%d+) Défense$", "DefenseRating"}, -- enchantement de paladin composé
	{"^%+?(%d+) Score de défense$", "DefenseRating"}, -- Ambre épais ; Jambières d'écailles de sang de défense
	{"^Équipé : Score de défense augmenté de (%d+)%.$", "DefenseRating"},
	{"^%+?(%d+) Score d'esquive$", "DodgeRating"}, -- Anneau arctique d'évitement
	{"^Équipé : Augmente votre score d'esquive de (%d+)%.$", "DodgeRating"}, -- Insigne de Loup-de-givre rang 6
	{"^Équipé : Augmente votre score de parade de (%d+)%.$", "ParryRating"}, -- Vengeur draconique
	{"^%+?(%d+) Score de parade$", "ParryRating"},
	{"^%(([%d%.,]+) dégâts par seconde%)$"}, -- Ignorer ceci ; les DPS sont calculés manuellement
	{"^Ajoute ([%d%.,]+) dégâts par seconde$", "Dps"},
	{"^Arme enflammée$", "Dps", 4, PawnMultipleStatsFixed}, -- enchantement d'arme
	{"^Équipé : Augmente votre score d'expertise de (%d+)%.$", "ExpertiseRating"}, -- Garde-terre
	{"^Équipé : Augmente de (%d+) le score d'expertise%.$", "ExpertiseRating"},
	{"^%+?(%d+) Score d'expertise$", "ExpertiseRating"}, -- Cristal d'ombre du gardien
	{"^Équipé : Augmente de (%d+) le score de coup critique%.$", "CritRating"},
	{"^Équipé : Améliore le score de coup critique de (%d+)%.$", "CritRating"},
	{"^Équipé : Augmente votre score de coup critique de (%d+)%.$", "CritRating"},
	{"^%+?(%d+) Score de critique$", "CritRating"}, -- Manteau de Malorne
	{"^%+?(%d+) Score de critique$", "CritRating"}, -- Opale de feu gravée (après normalisation)
	{"^%+?(%d+) Score de coup critique%.?$", "CritRating"}, -- Un enchantement de tête est "20 Score de coup critique." avec un point et minuscule
	{"^Lunette %(%+(%d+) Score de coup critique%)$", "CritRating"},
	{"^%+?(%d+) Coup critique à distance$", "CritRating"}, -- Lunette percecoeur (non testé) ; Pawn ne distingue pas entre score de critique à distance et hybride
	{"%+(%d+) au score de coup critique", "CritRating"},
	{"^Équipé : Augmente votre score de toucher de (%d+)%.$", "HitRating"}, -- Anneau de Don Julio
	{"^Équipé : Améliore le score de toucher de (%d+)%.$", "HitRating"},
	{"^%+?(%d+) Score de toucher$", "HitRating"}, -- lunette 3% de toucher
	{"^Pied sûr$", "HitRating", 10, PawnMultipleStatsFixed}, -- Enchantement (non testé) ; a des effets supplémentaires
	{"^Précision$", "HitRating", 25, PawnMultipleStatsFixed, "CritRating", 25, PawnMultipleStatsFixed}, -- enchantement d'arme
	{"^Équipé : Améliore votre score de résilience de (%d+)%.$", "ResilienceRating"},
	{"^%+?(%d+) Score de résilience$", "ResilienceRating"},
	{"^%+?(%d+) Résilience$", "ResilienceRating"}, -- Pierre de l'aube mystique sublime
	{"^Équipé : Augmente de (%d+) le score de hâte%.$", "HasteRating"},
	{"^Contrepoids %(%+(%d+) Score de hâte%)", "HasteRating"},
	{"^Équipé : Améliore le score de hâte de (%d+)%.$", "HasteRating"}, -- Épaulettes d'acier rapide
	{"^%+?(%d+) Score de hâte$", "HasteRating"}, -- Jambières du trahi
	{"^Équipé : Augmente votre score de maîtrise de (%d+)%.", "MasteryRating"}, -- Hache d'hast d'elementium (4.0) (Ne pas inclure $ ; le score de maîtrise inclut maintenant le nom de votre maîtrise sur l'objet.)
	{"^%+?(%d+) Score de maîtrise$", "MasteryRating"}, -- Joyau d'ambre fracturé (4.0).
	{"^Équipé : Augmente la puissance d'attaque de (%d+)%.$", "Ap"},
	{"^Équipé : Augmente la puissance d'attaque de (%d+)%.$", "Ap"},
	{"^%+?(%d+) Puissance d'attaque$", "Ap"},
	{"%+(%d+) Ã  la puissance d'attaque", "Ap"},
	{"%+(%d+) à la puissance d'attaque", "Ap"},
	{"ÃquipÃ© : Augmente de (%d+) la puissance d'attaque", "Ap"},
	{"Équipé : Augmente de (%d+) la puissance d'attaque", "Ap"},
	{"^%+?(%d+) Puissance d'attaque à distance$", "Rap"},
	{"^Équipé : Augmente la puissance d'attaque à distance de (%d+)%.$", "Rap"},
	{"^Équipé : Rend (%d+) points de mana toutes les 5 sec%.$", "Mp5"},
	{"^%+?(%d+) Régén. de mana$", "Mp5"}, -- enchantement d'épaule, Scripteurs ?
	{"^Régén. mana (%d+) toutes les 5 sec%.$", "Mp5"},
	{"^%+?(%d+) [mM]ana toutes les 5 sec%.?$", "Mp5"},
	{"^%+?(%d+) [mM]ana par 5 sec%.?$", "Mp5"},
	{"^%+?(%d+) [mM]ana toutes les 5 secondes$", "Mp5"}, -- Draénite d'ombre royale
	{"^%+?(%d+) [mM]ana par 5 sec%.$", "Mp5"},
	{"^%+?(%d+) [mM]ana toutes les 5 secondes$", "Mp5"},
	{"^%+(%d+) Mana récupéré toutes les 5 secondes$", "Mp5"}, -- Kit d'armure du magistère
	{"^Équipé : Rend (%d+) points de vie toutes les 5 sec%.$", "Hp5"},
	{"^Équipé : Rend (%d+) points de vie par 5 sec%.$", "Hp5"}, -- Oui, "toutes les" et "par" sont tous deux utilisés sur les objets...
	{"^%+?(%d+) [vV]ie toutes les 5 sec%.?$", "Hp5"}, -- Chevalière d'aigue-marine de régénération
	{"^%+?(%d+) [vV]ie par 5 sec%.?$", "Hp5"}, -- Collier d'anglésite de régénération
	{"^%+(%d+) Vie et mana toutes les 5 sec$", "Mp5", 1, PawnMultipleStatsExtract, "Hp5", 1, PawnMultipleStatsExtract}, -- enchantement de bottes Vitalité supérieure
	{"^%+(%d+) Mana$", "Mana"}, -- enchantement +150 mana
	{"^%+(%d+) PV$", "Health"}, -- enchantement de tête/jambes +100 points de vie
	{"^%+(%d+) Points de vie$", "Health"}, -- enchantement +150 points de vie
	{"^Armure : (%d+)$", "AutoArmor"},
	{"^(%d+) Armure$", "AutoArmor"}, -- armure normale
	{"^%+(%d+) Armure$", "BonusArmor"}, -- enchantements d'armure de cape
	{"^Renforcé %(%+(%d+) Armure%)$", "BonusArmor"}, -- kits d'armure
	{"^Équipé : %+(%d+) Armure%.$", "BonusArmor"}, -- sceau royal d'Eldre'Thalas de paladin
	{"^Équipé : Augmente la puissance des sorts de (%d+)%.$", "SpellPower"}, -- Épaulières de chaîne superposée
	{"^%+?(%d+) Puissance des sorts$", "SpellPower"}, -- Topaze de monarque téméraire
	{"%+(%d+) Ã  la puissance des sorts", "SpellPower"},
	{"%+(%d+) à la puissance des sorts", "SpellPower"},
	{"%+(%d+) aux dÃ©gÃ¢ts des sorts", "SpellPower"},
	{"^Équipé : Augmente le score de pénétration d'armure de (%d+)%.$", "ArmorPenetration"}, -- Cuirasse d'assaut, Ceinture de chaîne d'argent de Vereesa
	{"^Équipé : Augmente votre score de pénétration d'armure de (%d+)%.$", "ArmorPenetration"}, -- Écraseur de squelettes d'argent
	{"^%+?(%d+) Score de pénétration d'armure$", "ArmorPenetration"}, -- Rubis écarlate fracturé
	{"^Équipé : Augmente votre pénétration des sorts de (%d+)%.$", "SpellPenetration"}, -- Robe de givrefeu
	{"^%+?(%d+) Pénétration des sorts$", "SpellPenetraction"}, -- Talasite radieuse
	{"^%+(%d+) Dégâts de feu$", "FireSpellDamage"},
	{"^%+(%d+) Dégâts des sorts de feu$", "FireSpellDamage"},
	{"^Équipé : Augmente les dégâts infligés par les sorts et effets de Feu jusqu'à (%d+)%.$", "FireSpellDamage"},
	{"^Équipé : Augmente la puissance des sorts de feu de (%d+)%.$", "FireSpellDamage"},
	{"%+(%d+) aux dÃ©gÃ¢ts des sorts de Feu", "FireSpellDamage"},
	{"^%+(%d+) Dégâts d'ombre$", "ShadowSpellDamage"},
	{"^%+(%d+) Dégâts des sorts d'ombre$", "ShadowSpellDamage"},
	{"^Équipé : Augmente les dégâts infligés par les sorts et effets d'Ombre jusqu'à (%d+)%.$", "ShadowSpellDamage"},
	{"^Équipé : Augmente la puissance des sorts d'ombre de (%d+)%.$", "ShadowSpellDamage"}, -- Épaulières d'ombregivre gelée
	{"%+(%d+) aux dÃ©gÃ¢ts des sorts d'Ombre", "ShadowSpellDamage"},
	{"^%+(%d+) Dégâts de nature$", "NatureSpellDamage"}, -- Jambières du traqueur du Néant de colère de la nature
	{"^%+(%d+) Dégâts des sorts de nature$", "NatureSpellDamage"},
	{"^Équipé : Augmente les dégâts infligés par les sorts et effets de Nature jusqu'à (%d+)%.$", "NatureSpellDamage"},
	{"^Équipé : Augmente la puissance des sorts de nature de (%d+)%.$", "NatureSpellDamage"},
	{"%+(%d+) aux dÃ©gÃ¢ts des sorts de Nature", "NatureSpellDamage"},
	{"^%+(%d+) Dégâts des arcanes$", "ArcaneSpellDamage"},
	{"^%+(%d+) Dégâts des sorts des arcanes$", "ArcaneSpellDamage"}, -- Doigt de dragon de colère des arcanes
	{"^Équipé : Augmente les dégâts infligés par les sorts et effets des Arcanes jusqu'à (%d+)%.$", "ArcaneSpellDamage"},
	{"^Équipé : Augmente la puissance des sorts des arcanes de (%d+)%.$", "ArcaneSpellDamage"},
	{"%+(%d+) aux dÃ©gÃ¢ts des sorts des Arcanes", "ArcaneSpellDamage"},
	{"^%+(%d+) Dégâts de givre$", "FrostSpellDamage"},
	{"^%+(%d+) Dégâts des sorts de givre$", "FrostSpellDamage"}, -- enchantement
	{"%+(%d+) aux dÃ©gÃ¢ts des sorts de Givre", "FrostSpellDamage"},
	{"^Équipé : Augmente les dégâts infligés par les sorts et effets de Givre jusqu'à (%d+)%.$", "FrostSpellDamage"},
	{"^Équipé : Augmente la puissance des sorts de givre de (%d+)%.$", "FrostSpellDamage"}, -- Épaulières d'ombregivre gelée
	{"^%+(%d+) Dégâts du sacré$", "HolySpellDamage"},
	{"^%+(%d+) Dégâts des sorts du sacré$", "HolySpellDamage"},
	{"^Équipé : Augmente les dégâts infligés par les sorts et effets du Sacré jusqu'à (%d+)%.$", "HolySpellDamage"}, -- Lame forgée par la lumière
	{"^Équipé : Augmente les dégâts infligés par les sorts et effets du Sacré jusqu'à (%d+)%.$", "HolySpellDamage"}, -- Drapé du vertueux
	{"^Équipé : Augmente la puissance des sorts du sacré de (%d+)%.$", "HolySpellDamage"},
	{"^%+?(%d+) Toutes les résistances$", "AllResist"},
	{"^%+?(%d+) Résistance à tout$", "AllResist"}, -- Sphère prismatique
	{"^%+?(%d+) Résistance au feu$", "FireResist"},
	{"^%+(%d+) à la résistance au feu$", "FireResist"},
	{"^%+?(%d+) Résistance à l'ombre$", "ShadowResist"},
	{"^%+(%d+) à la résistance à l'ombre$", "ShadowResist"},
	{"^%+?(%d+) Résistance à la nature$", "NatureResist"},
	{"^%+(%d+) à la résistance à la nature$", "NatureResist"},
	{"^%+?(%d+) Résistance aux arcanes$", "ArcaneResist"},
	{"^%+(%d+) à la résistance aux arcanes$", "ArcaneResist"},
	{"^%+?(%d+) Résistance au givre$", "FrostResist"},
	{"^%+(%d+) à la résistance au givre$", "FrostResist"},
	{"^Châsse rouge$", "RedSocket", 1, PawnMultipleStatsFixed},
	{"^Châsse jaune$", "YellowSocket", 1, PawnMultipleStatsFixed},
	{"^Châsse bleue$", "BlueSocket", 1, PawnMultipleStatsFixed},
	{"^Châsse prismatique$", "PrismaticSocket", 1, PawnMultipleStatsFixed}, -- Les châsses prismatiques / incolores sont ajoutées par la forge
	{"^Châsse méta$", "MetaSocket", 1, PawnMultipleStatsFixed},
	{"^\"Ne rentre que dans un emplacement de gemme méta%.\"$", "MetaSocketEffect", 1, PawnMultipleStatsFixed}, -- Vraies gemmes méta, pas la châsse
	-- Scores d'équipement (patterns très fréquents dans les logs)
	{"ÃquipÃ© : Augmente de (%d+) le score de toucher", "HitRating"},
	{"ÃquipÃ© : Augmente de (%d+) le score d'esquive", "DodgeRating"},
	{"ÃquipÃ© : Augmente de (%d+) le score de parade", "ParryRating"},
	{"ÃquipÃ© : Augmente de (%d+) le score de blocage", "BlockRating"},
	{"ÃquipÃ© : Augmente de (%d+) le score de rÃ©silience", "ResilienceRating"},
	{"ÃquipÃ© : Augmente de (%d+) le score de pÃ©nÃ©tration d'armure", "ArmorPenetration"},
	{"ÃquipÃ© : Augmente de (%d+) le score de hÃ¢te", "HasteRating"},

	-- Versions avec accents corrects (au cas où l'encoding fix fonctionne)
	{"Équipé : Augmente de (%d+) le score de toucher", "HitRating"},
	{"Équipé : Augmente de (%d+) le score d'esquive", "DodgeRating"},
	{"Équipé : Augmente de (%d+) le score de parade", "ParryRating"},
	{"Équipé : Augmente de (%d+) le score de blocage", "BlockRating"},
	{"Équipé : Augmente de (%d+) le score de résilience", "ResilienceRating"},
	{"Équipé : Augmente de (%d+) le score de pénétration d'armure", "ArmorPenetration"},
	{"Équipé : Augmente de (%d+) le score de hâte", "HasteRating"},
	{"%+(%d+) au score de hÃ¢te", "HasteRating"},
	{"%+(%d+) au score de toucher", "HitRating"},

	-- Résistances avec encodage corrompu
	{"%+(%d+) Ã  la rÃ©sistance Feu", "FireResist"},
	{"%+(%d+) Ã  la rÃ©sistance Givre", "FrostResist"},
	{"%+(%d+) Ã  la rÃ©sistance Ombre", "ShadowResist"},
	{"%+(%d+) Ã  la rÃ©sistance Nature", "NatureResist"},
	{"%+(%d+) Ã  la rÃ©sistance Arcanes", "ArcaneResist"},

	-- Variantes "au" au lieu de "à la"
	{"%+(%d+) Ã  la rÃ©sistance au Givre", "FrostResist"},
	{"%+(%d+) au Givre", "FrostResist"},
	{"%+(%d+) au Feu", "FireResist"},

	-- Versions avec accents corrects
	{"%+(%d+) à la résistance Feu", "FireResist"},
	{"%+(%d+) à la résistance Givre", "FrostResist"},
	{"%+(%d+) à la résistance Ombre", "ShadowResist"},
	{"%+(%d+) à la résistance Nature", "NatureResist"},
	{"%+(%d+) à la résistance Arcanes", "ArcaneResist"},

	-- Points de vie
	{"%+(%d+) points de vie toutes les 5 sec", "Hp5"},

	-- Points de mana
	{"%+(%d+) points de mana toutes les 5 sec", "Mp5"},
	{"ÃquipÃ© : Rend (%d+) points de mana toutes les 5 secondes", "Mp5"},
	{"Équipé : Rend (%d+) points de mana toutes les 5 secondes", "Mp5"},

	-- Dégâts par type (armes)
	{"(%d+) %- (%d+) points de dÃ©gÃ¢ts %(Feu%)", "MinDamage", 1, "MaxDamage", 2},
	{"(%d+) %- (%d+) points de dÃ©gÃ¢ts %(Givre%)", "MinDamage", 1, "MaxDamage", 2},
	{"(%d+) %- (%d+) points de dÃ©gÃ¢ts %(Nature%)", "MinDamage", 1, "MaxDamage", 2},
	{"(%d+) %- (%d+) points de dÃ©gÃ¢ts %(Arcanes%)", "MinDamage", 1, "MaxDamage", 2},

	-- Score d'esquive spécifique trouvé dans les logs
	{"%+(%d+) au score d'esquive", "DodgeRating"},

	-- ========================================
	-- Chaînes rares qui sont ignorées (les communes sont en haut du fichier)
	-- ========================================
	{'^"'}, -- Texte de saveur
	{"^Augmente la puissance d'attaque de (%d+) uniquement sous forme de Chat, Ours, Ours redoutable et Sélénien%.$"}, -- Apparaît sur les armes pour les druides
	{"^Vallée d'Alterac$"}, -- Sang de soldat de Dent-de-givre
	{"^Profondeurs de Rochenoire$"}, -- Bière de la brune sombre
	{"^Monts Tranchantes$"}, -- Masque à gaz corrompu par les gangréens
	{"^Temple Noir$"}, -- Épine de Naj'entus
	{"^Hachoir$"}, -- Clé de la cour de Gordok
	{"^Collines de Grisonner$"}, -- Élément 115
	{"^Sommet d'Hyjal$"}, -- Larmes de la déesse
	{"^Couronne de glace$"}, -- (Quêtes journalières du tournoi d'Argent)
	{"^Karazhan$"}, -- Tourment du worgen
	{"^Contreforts de Hautebrande d'autrefois$"}, -- Paquet de bombes incendiaires
	{"^Caverne du sanctuaire du Serpent$"}, -- Noyau souillé
	{"^Vallée d'Ombrelune$"}, -- Tabard illidari enchanté
	{"^Stratholme$"}, -- Andonisus, faucheur d'âmes
	{"^Donjon de la Tempête$"}, -- Infuseur cosmique
	{"^L'évasion de Durnholde$"}, -- Paquet de bombes incendiaires
	{"^Le Noir marécage$"}, -- Chrono-balise
	{"^Joug-d'hiver$"}, -- Mines terrestres gonflables
	{"^Zul'Aman$"}, -- Bâton de maléfice amani
}

-- Ces expressions régulières fonctionnent exactement comme PawnRegexes, mais elles sont utilisées pour analyser le côté droit des infobulles.
-- Les stats non reconnues du côté droit sont toujours ignorées.
-- Les haches, masses et épées à deux mains verront leurs stats converties vers la version 2M plus tard.
PawnRightHandRegexes =
{
	{"^Vitesse ([%d%.,]+)$", "Speed"},
	{"^Flèche$", "IsBow", 1, PawnMultipleStatsFixed},
	{"^Hache$", "IsAxe", 1, PawnMultipleStatsFixed},
	{"^Arc$", "IsBow", 1, PawnMultipleStatsFixed},
	{"^Balle$", "IsGun", 1, PawnMultipleStatsFixed},
	{"^Arbalète$", "IsCrossbow", 1, PawnMultipleStatsFixed},
	{"^Dague$", "IsDagger", 1, PawnMultipleStatsFixed},
	{"^Arme de poing$", "IsFist", 1, PawnMultipleStatsFixed},
	{"^Arme à feu$", "IsGun", 1, PawnMultipleStatsFixed},
	{"^Masse$", "IsMace", 1, PawnMultipleStatsFixed},
	{"^Arme d'hast$", "IsPolearm", 1, PawnMultipleStatsFixed},
	{"^Bâton$", "IsStaff", 1, PawnMultipleStatsFixed},
	{"^Épée$", "IsSword", 1, PawnMultipleStatsFixed},
	{"^Arme de jet$", "IsThrown", 1, PawnMultipleStatsFixed},
	{"^Baguette$", "IsWand", 1, PawnMultipleStatsFixed},
	{"^Tissu$", "IsCloth", 1, PawnMultipleStatsFixed},
	{"^Cuir$", "IsLeather", 1, PawnMultipleStatsFixed},
	{"^Mailles$", "IsMail", 1, PawnMultipleStatsFixed},
	{"^Plaques$", "IsPlate", 1, PawnMultipleStatsFixed},
	{"^Bouclier$", "IsShield", 1, PawnMultipleStatsFixed},
	{"^EpÃ©e$", "IsSword", 1, PawnMultipleStatsFixed},
	{"^Tenu%(e%) en main gauche$", "IsOffHand", 1, PawnMultipleStatsFixed},
}