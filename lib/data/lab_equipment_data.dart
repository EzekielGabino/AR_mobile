import '../models/lab_equipment.dart';

LabEquipment? findEquipmentById(String? id) {
  if (id == null) return null;
  for (final equipment in sampleEquipmentList) {
    if (equipment.id == id) return equipment;
  }
  return null;
}

final List<LabEquipment> sampleEquipmentList = [
  const LabEquipment(
    id: 'Tube_brush',
    name: 'Tube Brush',
    imagePath: 'assets/equipment/Tube_brush.jpg',
    category: 'Cleaning',
    description:
        'A long, narrow brush with bristles on one end, designed to reach '
        'inside test tubes and other narrow glassware.',
    purpose: 'Cleaning the inside of test tubes and narrow-necked containers.',
    whenToUse:
        'Use after an experiment to scrub out residue before washing '
        'glassware with soap and water.',
    safetyTip:
        'Rinse residue-coated brushes immediately and avoid contact with '
        'strong acids or bases without gloves.',
  ),
  const LabEquipment(
    id: 'alcohol_lamp',
    name: 'Alcohol Lamp',
    imagePath: 'assets/equipment/alcohol_lamp.jpg',
    category: 'Heating',
    description:
        'A small glass lamp with a wick, filled with denatured alcohol, '
        'used to produce a gentle open flame for heating.',
    purpose: 'Providing a low, steady flame for heating small samples.',
    whenToUse:
        'Use when a gentler, less intense heat source than a Bunsen burner '
        'is needed.',
    safetyTip:
        'Always use the cap to extinguish the flame (never blow it out), '
        'and keep it away from flammable materials.',
  ),
  const LabEquipment(
    id: 'beaker',
    name: 'Beaker',
    imagePath: 'assets/equipment/beaker.jpg',
    category: 'Glassware',
    description:
        'A cylindrical container with a flat bottom and a small pouring '
        'spout, used to hold, mix, or heat liquids.',
    purpose: 'Mixing, stirring, and heating liquid substances.',
    whenToUse:
        'Use when preparing solutions or when precise volume measurement '
        'is not required.',
    safetyTip:
        'Do not fill beyond 3/4 full when heating, and use tongs or a '
        'heat-resistant glove when handling hot beakers.',
  ),
  const LabEquipment(
    id: 'boiling_flask',
    name: 'Boiling Flask',
    imagePath: 'assets/equipment/boiling_flask.jpg',
    category: 'Glassware',
    description:
        'A round-bottomed flask with a long neck, designed to withstand '
        'heating of liquids to boiling point.',
    purpose: 'Boiling or heating liquids evenly, often in distillation setups.',
    whenToUse:
        'Use when a liquid needs to be heated to boiling, especially in '
        'distillation or reflux setups.',
    safetyTip:
        'Use a stand and clamp to secure it while heating, and never heat '
        'a sealed flask.',
  ),
  const LabEquipment(
    id: 'boiling_flask_3_neck',
    name: '3-Neck Boiling Flask',
    imagePath: 'assets/equipment/boiling_flask_3_neck.jpg',
    category: 'Glassware',
    description:
        'A round-bottomed flask with three separate necks, allowing '
        'multiple instruments (thermometer, condenser, dropping funnel) '
        'to be attached at once.',
    purpose:
        'Running multi-step reactions that require simultaneous heating, '
        'stirring, and monitoring.',
    whenToUse:
        'Use in setups requiring more than one attachment at the same '
        'time, such as reflux with temperature monitoring.',
    safetyTip:
        'Ensure all necks are properly stoppered or fitted before heating '
        'to prevent vapor escape.',
  ),
  const LabEquipment(
    id: 'conical_flask',
    name: 'Conical (Erlenmeyer) Flask',
    imagePath: 'assets/equipment/conical_flask.jpg',
    category: 'Glassware',
    description:
        'A flask with a flat bottom, conical body, and narrow neck, '
        'allowing contents to be swirled without spilling.',
    purpose: 'Mixing, titration, and boiling liquids with minimal spillage.',
    whenToUse: 'Use during titration or when swirling reagents is needed.',
    safetyTip:
        'Never seal the neck completely while heating — pressure buildup '
        'can cause it to shatter.',
  ),
  const LabEquipment(
    id: 'crucible',
    name: 'Crucible',
    imagePath: 'assets/equipment/crucible.jpg',
    category: 'Heating',
    description:
        'A small, heat-resistant ceramic or porcelain container used to '
        'heat substances to very high temperatures.',
    purpose: 'Heating, melting, or igniting solid substances.',
    whenToUse:
        'Use when a sample must be heated to very high temperatures, such '
        'as in gravimetric analysis or ignition tests.',
    safetyTip:
        'Always use crucible tongs to handle it — never bare hands — and '
        'let it cool on a heat-resistant surface before touching nearby.',
  ),
  const LabEquipment(
    id: 'evaporating_dish',
    name: 'Evaporating Dish',
    imagePath: 'assets/equipment/evaporating_dish.jpg',
    category: 'Heating',
    description:
        'A shallow, wide dish made of porcelain or glass, used to '
        'evaporate liquids and leave behind dissolved solids.',
    purpose: 'Evaporating solvents to recover dissolved solids.',
    whenToUse:
        'Use when you need to evaporate a liquid to obtain a solid '
        'residue, such as in crystallization.',
    safetyTip:
        'Heat gradually and avoid sudden temperature changes to prevent '
        'cracking.',
  ),
  const LabEquipment(
    id: 'filter_flask',
    name: 'Filter (Büchner) Flask',
    imagePath: 'assets/equipment/filter_flask.jpg',
    category: 'Filtration',
    description:
        'A thick-walled flask with a side arm, used together with a '
        'Büchner funnel and vacuum pump for filtration.',
    purpose: 'Performing vacuum filtration to separate solids from liquids.',
    whenToUse:
        'Use when filtering a solid-liquid mixture quickly with the help '
        'of suction.',
    safetyTip:
        'Only use thick-walled flasks rated for vacuum use, since regular '
        'glassware can implode under pressure.',
  ),
  const LabEquipment(
    id: 'funnel',
    name: 'Funnel',
    imagePath: 'assets/equipment/funnel.jpg',
    category: 'Filtration',
    description:
        'A cone-shaped tool with a wide mouth and narrow stem, used to '
        'channel liquids or fine solids into a small opening.',
    purpose: 'Transferring liquids or performing gravity filtration.',
    whenToUse:
        'Use when transferring liquid into a narrow-necked container or '
        'filtering with filter paper.',
    safetyTip: 'Do not overfill — pour slowly to avoid splashing or overflow.',
  ),
  const LabEquipment(
    id: 'glass_rod',
    name: 'Glass Stirring Rod',
    imagePath: 'assets/equipment/glass_rod.jpg',
    category: 'Mixing',
    description:
        'A thin, solid glass rod used to stir, mix, or guide the flow of '
        'liquids during transfer.',
    purpose: 'Stirring solutions and guiding liquid during pouring.',
    whenToUse:
        'Use when mixing reagents or when transferring liquid along the '
        'rod to prevent splashing.',
    safetyTip:
        'Handle carefully — glass rods can chip or break and cause cuts.',
  ),
  const LabEquipment(
    id: 'graduated_cylinder',
    name: 'Graduated Cylinder',
    imagePath: 'assets/equipment/graduated_cylinder.jpg',
    category: 'Measuring',
    description:
        'A tall, narrow container marked with volume measurements for '
        'accurate liquid measurement.',
    purpose: 'Measuring precise volumes of liquid.',
    whenToUse: 'Use when accuracy of liquid volume matters more than a beaker.',
    safetyTip:
        'Read the measurement at eye level from the bottom of the '
        'meniscus to avoid parallax error.',
  ),
  const LabEquipment(
    id: 'medicine_dropper',
    name: 'Medicine Dropper',
    imagePath: 'assets/equipment/medicine_dropper.jpg',
    category: 'Measuring',
    description:
        'A small glass or plastic tube with a rubber bulb, used to '
        'transfer or measure liquids drop by drop.',
    purpose: 'Adding small, precise amounts of liquid reagent.',
    whenToUse:
        'Use when only a few drops of a substance are needed, such as an '
        'indicator in titration.',
    safetyTip:
        'Never use the same dropper for different chemicals without '
        'cleaning it first, to avoid contamination.',
  ),
  const LabEquipment(
    id: 'medicine_spoon',
    name: 'Medicine Spoon',
    imagePath: 'assets/equipment/medicine_spoon.jpg',
    category: 'Measuring',
    description:
        'A small spoon used to scoop and transfer measured amounts of '
        'powdered or granular substances.',
    purpose: 'Transferring small amounts of solid chemicals or samples.',
    whenToUse:
        'Use when measuring or transferring a small quantity of solid '
        'reagent.',
    safetyTip:
        'Use a separate, clean spoon for each chemical to prevent cross '
        'contamination.',
  ),
  const LabEquipment(
    id: 'mortar',
    name: 'Mortar and Pestle',
    imagePath: 'assets/equipment/mortar.jpg',
    category: 'Preparation',
    description:
        'A sturdy bowl (mortar) paired with a club-shaped tool (pestle), '
        'used to crush and grind solid substances into powder.',
    purpose: 'Grinding and crushing solid samples into fine powder.',
    whenToUse:
        'Use when a solid sample needs to be pulverized before further '
        'testing or dissolving.',
    safetyTip:
        'Clean thoroughly between uses to avoid contaminating the next '
        'sample.',
  ),
  const LabEquipment(
    id: 'plastic_wash_bottle',
    name: 'Plastic Wash Bottle',
    imagePath: 'assets/equipment/plastic_wash_bottle.jpg',
    category: 'Cleaning',
    description:
        'A squeezable plastic bottle with a narrow spout, used to dispense '
        'a controlled stream of distilled water or solvent.',
    purpose: 'Rinsing glassware and washing down residue from containers.',
    whenToUse:
        'Use when rinsing equipment or transferring the last traces of a '
        'sample into a container.',
    safetyTip:
        'Label the bottle clearly if it contains anything other than '
        'distilled water, to avoid mix-ups.',
  ),
  const LabEquipment(
    id: 'rubber_suction_bulb',
    name: 'Rubber Suction Bulb',
    imagePath: 'assets/equipment/rubber_suction_bulb.jpg',
    category: 'Measuring',
    description:
        'A rubber bulb attached to a pipette, used to draw liquid up '
        'without using the mouth.',
    purpose: 'Safely drawing and dispensing liquid through a pipette.',
    whenToUse:
        'Use whenever a pipette is needed to measure or transfer liquid — '
        'never pipette by mouth.',
    safetyTip:
        'Squeeze and release gently to avoid drawing liquid too far into '
        'the bulb.',
  ),
  const LabEquipment(
    id: 'separatory_funnel',
    name: 'Separatory Funnel',
    imagePath: 'assets/equipment/separatory_funnel.jpg',
    category: 'Filtration',
    description:
        'A pear-shaped funnel with a stopcock at the bottom, used to '
        'separate two immiscible liquids by density.',
    purpose: 'Separating liquid layers, such as in liquid-liquid extraction.',
    whenToUse:
        "Use when two liquids that don't mix (e.g. oil and water) need to "
        'be separated.',
    safetyTip:
        'Vent pressure periodically by opening the stopcock while '
        'inverted and shaking, to prevent the funnel from bursting open.',
  ),
  const LabEquipment(
    id: 'test_tube',
    name: 'Test Tube',
    imagePath: 'assets/equipment/test_tube.jpg',
    category: 'Glassware',
    description:
        'A small, thin cylindrical tube with a rounded bottom, used to '
        'hold small amounts of substances for reactions or heating.',
    purpose: 'Conducting small-scale reactions and observations.',
    whenToUse:
        "Use for quick, small-volume tests or reactions that don't need "
        'large quantities.',
    safetyTip:
        'Point the open end away from yourself and others when heating, '
        'and use a test tube holder.',
  ),
  const LabEquipment(
    id: 'volumetric_flask',
    name: 'Volumetric Flask',
    imagePath: 'assets/equipment/volumetric_flask.jpg',
    category: 'Measuring',
    description:
        'A flask with a narrow neck and a single calibration mark, '
        'designed to hold one precise volume at a specific temperature.',
    purpose: 'Preparing solutions of an exact, known concentration.',
    whenToUse:
        'Use when a solution must be diluted or prepared to an exact '
        'volume, such as for standard solutions.',
    safetyTip:
        'Do not heat a volumetric flask — heat can distort the glass and '
        'affect its calibrated accuracy.',
  ),
  const LabEquipment(
    id: 'wide_mouth_bottle',
    name: 'Wide Mouth Bottle',
    imagePath: 'assets/equipment/wide_mouth_bottle.jpg',
    category: 'Storage',
    description:
        'A sturdy bottle with a wide opening, used to store chemicals, '
        'especially solids or viscous substances.',
    purpose: 'Storing solid or semi-solid reagents and samples.',
    whenToUse:
        'Use when storing a substance that needs a wide opening for easy '
        'scooping or pouring, such as powders or crystals.',
    safetyTip:
        'Always label bottles clearly with contents and hazard symbols, '
        'and keep the cap tightly sealed when not in use.',
  ),
  const LabEquipment(
    id: 'safety_goggles',
    name: 'Safety Goggles',
    imagePath: 'assets/equipment/safety_goggles.png',
    category: 'Safety Gears',
    description:
        'Safety goggles are protective eyewear designed to cover and protect the eyes from chemicals, dust, and flying particles.',
    purpose:
        'They protect the eyes from injuries caused by chemical splashes and laboratory materials.',
    whenToUse:
        'Use safety goggles when conducting experiments involving chemicals, heat, glassware, or substances that may splash.',
    safetyTip:
        'Make sure the goggles fit properly and the lenses are clean and free from cracks or damage.',
  ),
  const LabEquipment(
    id: 'laboratory_gloves',
    name: 'Laboratory Gloves',
    imagePath: 'assets/equipment/laboratoty_gloves.jpg',
    category: 'Safety Gears',
    description:
        'Laboratory gloves are protective gloves made from materials such as nitrile or latex that protect the hands during laboratory activities.',
    purpose:
        'They help protect the hands from chemicals, contaminants, and potentially harmful substances.',
    whenToUse:
        'Wear gloves when handling chemicals, biological materials, or other substances that may irritate or harm the skin.',
    safetyTip:
        'Use the correct type of gloves for the material being handled and replace gloves immediately if they become damaged.',
  ),
  const LabEquipment(
    id: 'lab_coat',
    name: 'Lab Coat',
    imagePath: 'assets/equipment/lab_coat.jpg',
    category: 'Safety Gears',
    description:
        'A lab coat is a protective garment worn over regular clothing while working inside a laboratory.',
    purpose:
        'It protects the skin and clothing from chemical spills, splashes, and other laboratory materials.',
    whenToUse:
        'Wear a lab coat during laboratory experiments and activities involving chemicals or potentially hazardous materials.',
    safetyTip:
        'Keep the lab coat properly fastened and remove it before leaving the laboratory.',
  ),
  const LabEquipment(
    id: 'face_shield',
    name: 'Face Shield',
    imagePath: 'assets/equipment/face_shield.jpg',
    category: 'Safety Gears',
    description:
        'A face shield is a transparent protective covering that protects the face from splashes, particles, and other laboratory hazards.',
    purpose:
        'It provides additional protection for the face, especially during activities with a high risk of splashing.',
    whenToUse:
        'Use a face shield when working with corrosive chemicals, pressurized equipment, or procedures that may cause splashes.',
    safetyTip:
        'Clean the face shield regularly and use it together with safety goggles when eye protection is also required.',
  ),
  const LabEquipment(
    id: 'respiratory_mask',
    name: 'Respiratory Mask',
    imagePath: 'assets/equipment/respiratory_mask.png',
    category: 'Safety Gears',
    description:
        'A respiratory mask is protective equipment that covers the nose and mouth to reduce exposure to certain airborne hazards.',
    purpose:
        'It helps protect the respiratory system from specific particles, contaminants, or substances in the air.',
    whenToUse:
        'Use the appropriate respiratory protection when laboratory procedures require protection from airborne hazards.',
    safetyTip:
        'Always use the correct type of mask or respirator for the specific hazard and make sure it fits properly.',
  ),
  const LabEquipment(
    id: 'heat_resistant_gloves',
    name: 'Heat-Resistant Gloves',
    imagePath: 'assets/equipment/heat_resistant_gloves.jpg',
    category: 'Safety Gears',
    description:
        'Heat-resistant gloves are thick protective gloves designed to withstand high temperatures.',
    purpose:
        'They protect the hands from burns when handling hot laboratory equipment and materials.',
    whenToUse:
        'Use them when handling hot beakers, flasks, crucibles, or other heated equipment.',
    safetyTip:
        'Check the gloves for damage before use and never touch chemicals with gloves that have been contaminated.',
  ),
  const LabEquipment(
    id: 'safety_shoes',
    name: 'Safety Shoes',
    imagePath: 'assets/equipment/safety_shoes.jpg',
    category: 'Safety Gears',
    description:
        'Safety shoes are closed-toe footwear designed to protect the feet while working in the laboratory.',
    purpose:
        'They protect the feet from chemical spills, broken glass, and accidentally dropped equipment.',
    whenToUse: 'Wear safety shoes whenever performing laboratory activities.',
    safetyTip:
        'Always wear closed-toe shoes and avoid slippers, sandals, or other open footwear inside the laboratory.',
  ),
  const LabEquipment(
    id: 'fume_hood',
    name: 'Fume Hood',
    imagePath: 'assets/equipment/fume_hood.jpg',
    category: 'Safety Gears',
    description:
        'A fume hood is an enclosed and ventilated workspace designed to remove hazardous fumes, vapors, and gases.',
    purpose:
        'It reduces a person’s exposure to harmful chemicals released into the air.',
    whenToUse:
        'Use a fume hood when working with volatile, toxic, corrosive, or strongly irritating chemicals.',
    safetyTip:
        'Keep the fume hood free of unnecessary items and keep the sash at the recommended height while working.',
  ),
  const LabEquipment(
    id: 'fire_extinguisher',
    name: 'Fire Extinguisher',
    imagePath: 'assets/equipment/fire_extinguisher.jpg',
    category: 'Safety Gears',
    description:
        'A fire extinguisher is a portable device containing an extinguishing agent used to control small fires.',
    purpose:
        'It helps put out or control small laboratory fires before they spread.',
    whenToUse:
        'Use a fire extinguisher only for a small, manageable fire and when you have been properly trained to use it.',
    safetyTip:
        'Know the location of the fire extinguisher and use the correct type for the specific class of fire.',
  ),
  const LabEquipment(
    id: 'first_aid_kit',
    name: 'First Aid Kit',
    imagePath: 'assets/equipment/first_aid_kit.jpg',
    category: 'Safety Gears',
    description:
        'A first aid kit is a collection of medical supplies used to provide immediate care for minor injuries.',
    purpose:
        'It provides basic treatment for injuries such as small cuts, minor burns, and other common laboratory accidents.',
    whenToUse:
        'Use the first aid kit when a minor injury occurs during laboratory activities.',
    safetyTip:
        'Report all laboratory injuries to the teacher or laboratory supervisor, even after providing basic first aid.',
  ),
];
