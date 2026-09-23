/// Minimal bilingual string lookup — no full i18n infrastructure needed.
/// Add keys here and call [str(key, lang)] from any widget.
/// Falls back to Marathi, then the raw key if nothing matches.
const Map<String, Map<String, String>> kStrings = {
  'mr': {
    // App identity
    'app_name': 'कबाडी सेतू',

    // Launch screen
    'language_prompt': 'भाषा निवडा',

    // Role screen
    'role_prompt': 'भूमिका निवडा',
    'collector': 'संग्रहक',
    'recycler': 'पुनर्चक्रक',

    // Collector home
    'rate_board_title': 'भाव पत्रक',
    'add_material': 'साहित्य जोडा',
    'per_kg': 'प्रति किलो',

    // Capture screen
    'capture_hint': 'कचरा फोटो काढा',

    // Weigh screen
    'record_weight': 'वजन नोंद',
    'type_weight': 'किंवा थेट वजन टाइप करा',
    'quick_add': 'त्वरित जोडा',

    // Recycler home / gate
    'scan_hint': 'QR स्कॅन करण्यासाठी सज्ज',
    'waiting_scan': 'स्कॅनची वाट',

    // Quote & match
    'find_recycler': 'पुनर्चक्रक शोधा',
    'your_quote': 'तुमचा अंदाज',
    'recyclers_near_you': 'जवळचे अधिकृत खरेदीदार',
    'verified_centers': '५ नोंदणीकृत केंद्र उपलब्ध • ऑफलाइन डेटा',
    'you_keep': 'तुम्हाला मिळतील',
    'best_value': 'सर्वोत्तम दर',
    'cpcb_authorised': 'CPCB अधिकृत',
    'not_authorised': 'अनधिकृत',
    'free_pickup': 'मोफत पिकअप',
    'self_transport': 'स्वतः वाहतूक',
    'km_away': 'कि.मी. दूर',
    'proceed_handover': 'हस्तांतरण सुरू करा',

    // Handover
    'handover_ready': 'हस्तांतरणास तयार',
    'handover_token': 'हस्तांतरण टोकन',
    'offline_verified': 'ऑफलाइन सत्यापित',
    'ref_code': 'संदर्भ कोड',
    'scan_instruction': 'पुनर्चक्रक कर्मचाऱ्याला हा कोड स्कॅन करू द्या',
    'total_payout': 'एकूण देय रक्कम',
    'cash_pending': 'रोख प्रलंबित',
    'done': 'पूर्ण झाले',

    // Receipt
    'mark_paid': 'रोख प्राप्त',
    'share_receipt': 'पावती शेअर करा',

    // Ledger
    'ledger_title': 'नोंदवही',
    'this_week': 'या आठवड्यात',
    'weekly_earnings': 'या आठवड्याची कमाई',
    'past_transactions': 'मागील व्यवहार',
    'total_scrap': 'एकूण भंगार',

    // Safety
    'safety_title': 'सावधानता',
    'safety_ok': 'समजले, पुढे चला',
    'hazard_check': 'घातक कचरा तपासणी',
    'safety_alert': 'सुरक्षा इशारा',
    'battery_warning': 'बॅटरी कापू किंवा फोडू नका!',
    'battery_instruction': 'विषारी वायू आणि आगीचा धोका असतो. कोरड्या जागेत वेगळे ठेवा.',
    'crt_warning': 'काच फुटू देऊ नका!',
    'crt_instruction': 'सीसेयुक्त काच विषारी असते. हळूवार हाताळा.',
    'lead_warning': 'अॅसिड सांडू देऊ नका!',
    'lead_instruction': 'सल्फ्यूरिक अॅसिडमुळे भाजण्याची शक्यता. हातमोजे वापरा.',

    // Category selection
    'ai_suggestions': 'AI शिफारसी (शीर्ष ३)',
    'choose_other_category': 'इतर वस्तू आहे? सर्व १० श्रेणी पहा',
    'all_categories_title': 'सर्व ई-कचरा श्रेणी (१०)',
    'tap_to_select': 'निवडण्यासाठी श्रेणीवर टॅप करा',
    'selected_badge': 'निवडलेले',
    'hazard_badge': 'घातक कचरा',

    // Camera viewfinder & permissions
    'camera_permission_required': 'कॅमेरा परवानगी आवश्यक',
    'camera_permission_desc': 'भंगाराचा फोटो काढण्यासाठी कॅमेरा परवानगी द्या किंवा थेट श्रेणी निवडा.',
    'grant_permission': 'परवानगी द्या / पुन्हा प्रयत्न करा',
    'skip_to_category': 'फोटोशिवाय श्रेणी निवडा →',
    'camera_loading': 'कॅमेरा सुरू होत आहे...',

    // Image scan detection reasons
    'detected_green_pcb': 'हिरवा रंग आढळला • सर्किट बोर्ड (PCB)',
    'detected_copper_cable': 'तांबूस रंग आढळला • केबल / वायर',
    'detected_dark_battery': 'गडद धातू आढळला • बॅटरी / मोटार',
    'detected_light_plastic': 'हलका रंग आढळला • मिश्र प्लास्टिक',
    'demo_samples': 'नमुना स्कॅन',

    // Circular Economy & Eco Impact
    'eco_impact_title': 'चक्रीय अर्थव्यवस्था प्रभाव (Circular Impact)',
    'co2_saved': 'टाळलेले CO₂ उत्सर्जन',
    'copper_recovered': 'पुनर्प्राप्त तांबे (Copper)',
    'precious_metals': 'मौल्यवान धातू (Au/Ag)',
    'circular_badge': 'JNARDDC मानके',
    'listen_quote': 'किंमत अंदाज ऐका',
    'listen_receipt': 'पावती तपशील ऐका',
    'demo_mode': '⚡ ज्युरी डेमो',
    'demo_lot_loaded': 'डेमो लॉट तयार (६५ किलो)',
    'dos_and_donts': 'सुरक्षा हाताळणी नियम',
    'wear_gloves': 'जाड हातमोजे वापरा',
    'keep_dry': 'कोरड्या पेटीत ठेवा',
    'no_puncture': 'छिद्र करू नका किंवा जाळू नका',
  },
  'hi': {
    // App identity
    'app_name': 'कबाडी सेतू',

    // Launch screen
    'language_prompt': 'भाषा चुनें',

    // Role screen
    'role_prompt': 'भूमिका चुनें',
    'collector': 'संग्रहक',
    'recycler': 'पुनर्चक्रक',

    // Collector home
    'rate_board_title': 'दर सूची',
    'add_material': 'सामग्री जोड़ें',
    'per_kg': 'प्रति किलो',

    // Capture screen
    'capture_hint': 'कचरे की फोटो लें',

    // Weigh screen
    'record_weight': 'वज़न दर्ज करें',
    'type_weight': 'या सीधा वज़न टाइप करें',
    'quick_add': 'त्वरित जोड़ें',

    // Recycler home / gate
    'scan_hint': 'QR स्कैन के लिए तैयार',
    'waiting_scan': 'स्कैन का इंतज़ार',

    // Quote & match
    'find_recycler': 'पुनर्चक्रक खोजें',
    'your_quote': 'आपका अनुमान',
    'recyclers_near_you': 'नज़दीकी अधिकृत खरीदार',
    'verified_centers': '५ पंजीकृत केंद्र उपलब्ध • ऑफलाइन डेटा',
    'you_keep': 'आपको मिलेंगे',
    'best_value': 'सर्वोत्तम दर',
    'cpcb_authorised': 'CPCB अधिकृत',
    'not_authorised': 'अनधिकृत',
    'free_pickup': 'मुफ़्त पिकअप',
    'self_transport': 'स्वयं परिवहन',
    'km_away': 'कि.मी. दूर',
    'proceed_handover': 'हस्तांतरण शुरू करें',

    // Handover
    'handover_ready': 'हस्तांतरण तैयार',
    'handover_token': 'हस्तांतरण टोकन',
    'offline_verified': 'ऑफलाइन सत्यापित',
    'ref_code': 'संदर्भ कोड',
    'scan_instruction': 'पुनर्चक्रक कर्मचारी को यह कोड स्कैन करने दें',
    'total_payout': 'कुल देय राशि',
    'cash_pending': 'नकद बकाया',
    'done': 'पूर्ण हुआ',

    // Receipt
    'mark_paid': 'नकद प्राप्त',
    'share_receipt': 'रसीद शेयर करें',

    // Ledger
    'ledger_title': 'बही-खाता',
    'this_week': 'इस सप्ताह',
    'weekly_earnings': 'इस सप्ताह की कमाई',
    'past_transactions': 'पिछले लेन-देन',
    'total_scrap': 'कुल कबाड़',

    // Safety
    'safety_title': 'सावधानी',
    'safety_ok': 'समझ गया, आगे बढ़ें',
    'hazard_check': 'खतरनाक कचरा जाँच',
    'safety_alert': 'सुरक्षा चेतावनी',
    'battery_warning': 'बैटरी काटें या तोड़ें नहीं!',
    'battery_instruction': 'जहरीली गैस और आग का खतरा। सूखी जगह पर अलग रखें।',
    'crt_warning': 'कांच टूटने न दें!',
    'crt_instruction': 'सीसायुक्त कांच जहरीला होता है। सावधानी से संभालें।',
    'lead_warning': 'एसिड गिरने न दें!',
    'lead_instruction': 'सल्फ्यूरिक एसिड से जलने का खतरा। दस्ताने पहनें।',

    // Category selection
    'ai_suggestions': 'AI सुझाव (शीर्ष ३)',
    'choose_other_category': 'अन्य सामग्री है? सभी १० श्रेणियाँ देखें',
    'all_categories_title': 'सभी ई-कचरा श्रेणियाँ (१०)',
    'tap_to_select': 'चुनने के लिए श्रेणी पर टैप करें',
    'selected_badge': 'चुना गया',
    'hazard_badge': 'खतरनाक कचरा',

    // Camera viewfinder & permissions
    'camera_permission_required': 'कैमरा अनुमति आवश्यक',
    'camera_permission_desc': 'कबाड़ की फोटो लेने के लिए कैमरा अनुमति दें या सीधे श्रेणी चुनें।',
    'grant_permission': 'अनुमति दें / पुन: प्रयास करें',
    'skip_to_category': 'फोटो के बिना श्रेणी चुनें →',
    'camera_loading': 'कैमरा शुरू हो रहा है...',

    // Image scan detection reasons
    'detected_green_pcb': 'हरा रंग पाया गया • सर्किट बोर्ड (PCB)',
    'detected_copper_cable': 'ताम्र रंग पाया गया • केबल / तार',
    'detected_dark_battery': 'गहरा धातु पाया गया • बैटरी / मोटर',
    'detected_light_plastic': 'हल्का रंग पाया गया • मिश्रित प्लास्टिक',
    'demo_samples': 'नमूना स्कैन',

    // Circular Economy & Eco Impact
    'eco_impact_title': 'चक्रीय अर्थव्यवस्था प्रभाव (Circular Impact)',
    'co2_saved': 'बचाया गया CO₂ उत्सर्जन',
    'copper_recovered': 'पुनर्प्राप्त तांबा (Copper)',
    'precious_metals': 'कीमती धातुएं (Au/Ag)',
    'circular_badge': 'JNARDDC मानक',
    'listen_quote': 'भाव अनुमान सुनें',
    'listen_receipt': 'रसीद विवरण सुनें',
    'demo_mode': '⚡ जूरी डेमो',
    'demo_lot_loaded': 'डेमो लॉट तैयार (65 किलो)',
    'dos_and_donts': 'सुरक्षा नियम (Dos & Don’ts)',
    'wear_gloves': 'मोटे दस्ताने पहनें',
    'keep_dry': 'सूखे बक्से में रखें',
    'no_puncture': 'पंचर न करें या जलाएं नहीं',
  },
  'en': {
    // App identity
    'app_name': 'Kabadi Setu',

    // Launch screen
    'language_prompt': 'Choose Language',

    // Role screen
    'role_prompt': 'Select Role',
    'collector': 'Collector',
    'recycler': 'Recycler',

    // Collector home
    'rate_board_title': 'Rate Board',
    'add_material': 'Add Material',
    'per_kg': 'per kg',

    // Capture screen
    'capture_hint': 'Photograph scrap material',

    // Weigh screen
    'record_weight': 'Record Weight',
    'type_weight': 'Or type weight directly',
    'quick_add': 'Quick Add',

    // Recycler home / gate
    'scan_hint': 'Ready to scan QR token',
    'waiting_scan': 'Waiting for token scan...',

    // Quote & match
    'find_recycler': 'Find Recycler',
    'your_quote': 'Your Quote',
    'recyclers_near_you': 'Authorized Recyclers Near You',
    'verified_centers': '5 Registered Centers • Offline Data',
    'you_keep': 'You Keep',
    'best_value': 'Best Value',
    'cpcb_authorised': 'CPCB Authorised',
    'not_authorised': 'Unauthorised',
    'free_pickup': 'Free Pickup',
    'self_transport': 'Self Transport',
    'km_away': 'km away',
    'proceed_handover': 'Proceed to Handover',

    // Handover
    'handover_ready': 'Ready for Handover',
    'handover_token': 'Handover Token',
    'offline_verified': 'Offline Verified',
    'ref_code': 'Reference Code',
    'scan_instruction': 'Present this QR code to the recycler staff',
    'total_payout': 'Total Payout',
    'cash_pending': 'Cash Pending',
    'done': 'Done',

    // Receipt
    'mark_paid': 'Mark Paid (Cash)',
    'share_receipt': 'Share Receipt',

    // Ledger
    'ledger_title': 'Passbook Ledger',
    'this_week': 'This Week',
    'weekly_earnings': "This Week's Earnings",
    'past_transactions': 'Past Transactions',
    'total_scrap': 'Total Scrap',

    // Safety
    'safety_title': 'Safety Alert',
    'safety_ok': 'Got it, Continue',
    'hazard_check': 'Hazardous Material Check',
    'safety_alert': 'SAFETY ALERT',
    'battery_warning': 'Do Not Puncture or Burn Batteries!',
    'battery_instruction': 'Risk of toxic fumes and fire. Keep separate in a dry crate.',
    'crt_warning': 'Do Not Break Leaded Glass!',
    'crt_instruction': 'Leaded CRT glass contains toxic heavy metals. Handle gently.',
    'lead_warning': 'Do Not Tip or Spill Acid!',
    'lead_instruction': 'Sulfuric acid causes severe chemical burns. Wear safety gloves.',

    // Category selection
    'ai_suggestions': 'Top AI Suggestions',
    'choose_other_category': 'Something else? View all 10 categories',
    'all_categories_title': 'All E-Waste Categories (10)',
    'tap_to_select': 'Tap a category to select',
    'selected_badge': 'Selected',
    'hazard_badge': 'Hazardous',

    // Camera viewfinder & permissions
    'camera_permission_required': 'Camera Permission Required',
    'camera_permission_desc': 'Allow camera access to photograph scrap, or skip directly to category selection.',
    'grant_permission': 'Grant Permission / Retry',
    'skip_to_category': 'Skip Photo & Select Category →',
    'camera_loading': 'Starting camera viewfinder...',

    // Image scan detection reasons
    'detected_green_pcb': 'Green hue detected • Circuit Board (PCB)',
    'detected_copper_cable': 'Copper/Red hue detected • Cable / Wire',
    'detected_dark_battery': 'Dark/Metallic hue detected • Battery / Motor',
    'detected_light_plastic': 'Light polymer detected • Mixed Plastic',
    'demo_samples': 'Demo Simulation',

    // Circular Economy & Eco Impact
    'eco_impact_title': 'Circular Economy Impact',
    'co2_saved': 'CO₂ Emissions Prevented',
    'copper_recovered': 'Copper Recovered',
    'precious_metals': 'Precious Metals (Au/Ag)',
    'circular_badge': 'JNARDDC Norms',
    'listen_quote': 'Listen to Quote',
    'listen_receipt': 'Listen to Receipt',
    'demo_mode': '⚡ Jury Demo',
    'demo_lot_loaded': 'Demo Lot Ready (65 kg)',
    'dos_and_donts': 'Safety Guidelines',
    'wear_gloves': 'Wear heavy gloves',
    'keep_dry': 'Store in dry crate',
    'no_puncture': 'Do not puncture/burn',
  },
};

/// Returns the string for [key] in [lang].
/// Falls back to English, then Marathi, then the raw key itself — never throws.
String str(String key, String lang) =>
    kStrings[lang]?[key] ?? kStrings['en']?[key] ?? kStrings['mr']?[key] ?? key;
