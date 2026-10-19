import 'package:flutter/material.dart';
import '../models/safety_item.dart';
import '../theme/app_theme.dart';

final List<SafetyItem> kDos = [
  SafetyItem(
    id: 'do_ppe',
    group: SafetyGroup.doRule,
    code: 'DO',
    title: "Wear Your PPE",
    shortDescription:
        "Goggles, gloves, and a lab gown on before any experiment begins.",
    detail:
        "Personal protective equipment is your first line of defense. Safety "
        "goggles shield your eyes from splashes, gloves prevent skin contact "
        "with chemicals, and a buttoned lab gown protects clothing and skin "
        "from spills.",
    noteLabel: "Safety Tip",
    note:
        "Check goggles and gloves for cracks or tears before each use — "
        "damaged PPE won't protect you.",
    icon: Icons.check_circle,
    accentColor: SafetyColors.green,
  ),
  SafetyItem(
    id: 'do_labels',
    group: SafetyGroup.doRule,
    code: 'DO',
    title: "Read Labels First",
    shortDescription:
        "Check the container label and safety data sheet before you touch anything.",
    detail:
        "Never assume you know what's in an unlabeled or partially "
        "labeled container. Read the full label, including hazard "
        "pictograms, before measuring, pouring, or heating a substance.",
    noteLabel: "Safety Tip",
    note:
        "If a label is missing or unreadable, do not use the substance — "
        "ask your teacher instead.",
    icon: Icons.check_circle,
    accentColor: SafetyColors.green,
  ),
  SafetyItem(
    id: 'do_secure',
    group: SafetyGroup.doRule,
    code: 'DO',
    title: "Tie Back Hair & Secure Clothing",
    shortDescription:
        "Keep loose hair, sleeves, and jewelry away from flames and moving parts.",
    detail:
        "Loose hair and clothing can catch fire near a burner or get "
        "caught in equipment. Tie hair back and roll up long sleeves "
        "before starting.",
    noteLabel: "Safety Tip",
    note: "Scarves and dangling jewelry should be removed, not just tucked in.",
    icon: Icons.check_circle,
    accentColor: SafetyColors.green,
  ),
  SafetyItem(
    id: 'do_exits',
    group: SafetyGroup.doRule,
    code: 'DO',
    title: "Know Your Exits",
    shortDescription:
        "Locate the eyewash station, fire extinguisher, and emergency exit on entry.",
    detail:
        "Before starting any activity, take 30 seconds to find the "
        "nearest safety shower, eyewash station, fire extinguisher, and "
        "exit route. In an emergency you won't have time to look.",
    noteLabel: "Safety Tip",
    note:
        "Make this a habit every time you enter a new lab room, not just the first time.",
    icon: Icons.check_circle,
    accentColor: SafetyColors.green,
  ),
  SafetyItem(
    id: 'do_report',
    group: SafetyGroup.doRule,
    code: 'DO',
    title: "Report Spills Immediately",
    shortDescription:
        "Tell your teacher right away — no matter how small the spill looks.",
    detail:
        "Even a small chemical spill can release harmful vapors or "
        "create a slip hazard. Alert your instructor immediately so it "
        "can be contained and cleaned up properly.",
    noteLabel: "Safety Tip",
    note:
        "Never try to clean an unknown chemical spill yourself — wait for guidance.",
    icon: Icons.check_circle,
    accentColor: SafetyColors.green,
  ),
  SafetyItem(
    id: 'do_wash',
    group: SafetyGroup.doRule,
    code: 'DO',
    title: "Wash Hands After Lab",
    shortDescription:
        "Wash thoroughly before leaving, even if you wore gloves the whole time.",
    detail:
        "Gloves can develop micro-tears you don't notice, and residue "
        "can transfer when you remove them. Washing your hands is the "
        "last safety step of every session.",
    noteLabel: "Safety Tip",
    note: "Use soap and water, not just a hand-sanitizer wipe.",
    icon: Icons.check_circle,
    accentColor: SafetyColors.green,
  ),
];

final List<SafetyItem> kDonts = [
  SafetyItem(
    id: 'dont_eat',
    group: SafetyGroup.dontRule,
    code: "DON'T",
    title: "Never Eat or Drink",
    shortDescription: "Food and drinks can absorb chemical vapors and residue.",
    detail:
        "Consuming food or drink in the lab risks ingesting chemical "
        "contamination, even from surfaces that look clean. This "
        "includes chewing gum and applying lip balm.",
    noteLabel: "Safety Tip",
    note: "Store snacks and water bottles outside the lab, not on the bench.",
    icon: Icons.cancel,
    accentColor: SafetyColors.red,
  ),
  SafetyItem(
    id: 'dont_alone',
    group: SafetyGroup.dontRule,
    code: "DON'T",
    title: "Never Work Alone",
    shortDescription:
        "Always have a partner, classmate, or supervisor present.",
    detail:
        "If an accident happens while you're alone, there's no one to "
        "help or call for aid. Laboratory work always requires at least "
        "one other person present.",
    noteLabel: "Safety Tip",
    note: "This applies even for 'quick' tasks that seem low-risk.",
    icon: Icons.cancel,
    accentColor: SafetyColors.red,
  ),
  SafetyItem(
    id: 'dont_pipette',
    group: SafetyGroup.dontRule,
    code: "DON'T",
    title: "Never Pipette by Mouth",
    shortDescription: "Use a pipette bulb or mechanical pipettor instead.",
    detail:
        "Mouth pipetting can draw hazardous liquid directly into your "
        "mouth or lungs. Always use a bulb, syringe, or mechanical "
        "pipettor to transfer liquids.",
    noteLabel: "Safety Tip",
    note:
        "This rule has no exceptions, even for substances you believe are harmless.",
    icon: Icons.cancel,
    accentColor: SafetyColors.red,
  ),
  SafetyItem(
    id: 'dont_mix',
    group: SafetyGroup.dontRule,
    code: "DON'T",
    title: "Never Mix Chemicals Randomly",
    shortDescription:
        "Unlisted combinations can react violently or release toxic gas.",
    detail:
        "Only combine substances according to the exact procedure "
        "given. Mixing chemicals 'to see what happens' can produce "
        "heat, toxic fumes, or explosions.",
    noteLabel: "Safety Tip",
    note:
        "If a procedure doesn't specify an order or ratio, ask before improvising.",
    icon: Icons.cancel,
    accentColor: SafetyColors.red,
  ),
  SafetyItem(
    id: 'dont_flame',
    group: SafetyGroup.dontRule,
    code: "DON'T",
    title: "Never Leave Flames Unattended",
    shortDescription: "A lit burner left alone is a fire and burn risk.",
    detail:
        "An open flame can ignite nearby materials or clothing within "
        "seconds. Turn it off completely whenever you step away from "
        "your station, even briefly.",
    noteLabel: "Safety Tip",
    note:
        "Double-check the gas valve is fully closed, not just the flame extinguished.",
    icon: Icons.cancel,
    accentColor: SafetyColors.red,
  ),
  SafetyItem(
    id: 'dont_footwear',
    group: SafetyGroup.dontRule,
    code: "DON'T",
    title: "Never Wear Sandals or Loose Clothes",
    shortDescription:
        "Closed shoes protect your feet from spills and dropped glassware.",
    detail:
        "Open footwear leaves your feet exposed to chemical splashes "
        "and broken glass. Closed, flat shoes and fitted clothing are "
        "required lab attire.",
    noteLabel: "Safety Tip",
    note:
        "Aprons or lab gowns should be knee-length or longer for full coverage.",
    icon: Icons.cancel,
    accentColor: SafetyColors.red,
  ),
];
