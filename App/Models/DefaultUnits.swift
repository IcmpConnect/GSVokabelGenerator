import Foundation

public struct DefaultUnits {
    public static var allUnits: [VocabularyUnit] {
        return [
            unit1Pets,
            unit1Colours,
            unit1Numbers,
            unit1InMyRoom,
            unit2School,
            unit2TownPart1,
            unit2TownPart2,
            unit3Animals,
            unit3Birthday,
            unit3TheYear,
            unit4Shopping,
            unit5FreeTimePart1,
            unit5FreeTimePart2,
            unit6Feelings,
            unit8AtHome
        ]
    }

    public static let unit1Pets = VocabularyUnit(
        classNumber: 3,
        unitNumber: 1,
        title: "pets and other animals",
        deadlineDay: "Freitag",
        pairs: [
            VocabularyPair(english: "hamster", german: "der Hamster"),
            VocabularyPair(english: "cat", german: "die Katze"),
            VocabularyPair(english: "fish", german: "der Fisch"),
            VocabularyPair(english: "dog", german: "der Hund"),
            VocabularyPair(english: "guinea pig", german: "das Meerschweinchen"),
            VocabularyPair(english: "rabbit", german: "der Hase"),
            VocabularyPair(english: "tortoise", german: "die Schildkröte"),
            VocabularyPair(english: "mouse / mice", german: "die Maus / die Mäuse"),
            VocabularyPair(english: "snake", german: "die Schlange"),
            VocabularyPair(english: "budgie", german: "der Wellensittich"),
            VocabularyPair(english: "rats", german: "die Ratten"),
            VocabularyPair(english: "pony", german: "das Pony"),
            VocabularyPair(english: "spider", german: "die Spinne")
        ]
    )

    public static let unit2TownPart1 = VocabularyUnit(
        classNumber: 3,
        unitNumber: "2.1",
        title: "In town (part 1)",
        deadlineDay: "Freitag",
        pairs: [
            VocabularyPair(english: "hospital", german: "das Krankenhaus"),
            VocabularyPair(english: "museum", german: "das Museum"),
            VocabularyPair(english: "cinema", german: "das Kino"),
            VocabularyPair(english: "zoo", german: "der Zoo"),
            VocabularyPair(english: "library", german: "die Bücherei"),
            VocabularyPair(english: "post office", german: "die Post"),
            VocabularyPair(english: "sweet shop", german: "der Süßigkeitenladen"),
            VocabularyPair(english: "playground", german: "der Spielplatz"),
            VocabularyPair(english: "bus stop", german: "die Bushaltestelle"),
            VocabularyPair(english: "train station", german: "der Bahnhof"),
            VocabularyPair(english: "bridge", german: "die Brücke")
        ]
    )

    public static let unit2TownPart2 = VocabularyUnit(
        classNumber: 3,
        unitNumber: "2.2",
        title: "In town (part 2)",
        deadlineDay: "Freitag",
        pairs: [
            VocabularyPair(english: "turn left", german: "links abbiegen"),
            VocabularyPair(english: "between", german: "zwischen"),
            VocabularyPair(english: "go straight on", german: "gehe geradeaus"),
            VocabularyPair(english: "go across", german: "gehe über"),
            VocabularyPair(english: "behind", german: "hinter"),
            VocabularyPair(english: "next to", german: "neben"),
            VocabularyPair(english: "opposite", german: "gegenüber"),
            VocabularyPair(english: "turn right", german: "rechts abbiegen"),
            VocabularyPair(english: "in front of", german: "vor")
        ]
    )

    public static let unit3Birthday = VocabularyUnit(
        classNumber: 3,
        unitNumber: 3,
        title: "Birthday",
        deadlineDay: "Freitag",
        pairs: [
            VocabularyPair(english: "party", german: "das Fest / die Party"),
            VocabularyPair(english: "present", german: "das Geschenk"),
            VocabularyPair(english: "invitation", german: "die Einladung"),
            VocabularyPair(english: "cake", german: "der Kuchen"),
            VocabularyPair(english: "spring", german: "der Frühling"),
            VocabularyPair(english: "summer", german: "der Sommer"),
            VocabularyPair(english: "autumn", german: "der Herbst"),
            VocabularyPair(english: "winter", german: "der Winter"),
            VocabularyPair(english: "seasons", german: "die Jahreszeiten")
        ]
    )

    public static let unit3TheYear = VocabularyUnit(
        classNumber: 4,
        unitNumber: 3,
        title: "The year",
        deadlineDay: "Freitag",
        pairs: [
            VocabularyPair(english: "January", german: "Januar"),
            VocabularyPair(english: "February", german: "Februar"),
            VocabularyPair(english: "March", german: "März"),
            VocabularyPair(english: "April", german: "April"),
            VocabularyPair(english: "May", german: "Mai"),
            VocabularyPair(english: "June", german: "Juni"),
            VocabularyPair(english: "July", german: "Juli"),
            VocabularyPair(english: "August", german: "August"),
            VocabularyPair(english: "September", german: "September"),
            VocabularyPair(english: "October", german: "Oktober"),
            VocabularyPair(english: "November", german: "November"),
            VocabularyPair(english: "December", german: "Dezember")
        ]
    )

    public static let unit4Shopping = VocabularyUnit(
        classNumber: 4,
        unitNumber: 4,
        title: "Shopping",
        deadlineDay: "Freitag",
        pairs: [
            VocabularyPair(english: "ten", german: "Zehn"),
            VocabularyPair(english: "twenty", german: "Zwanzig"),
            VocabularyPair(english: "thirty", german: "Dreißig"),
            VocabularyPair(english: "forty", german: "Vierzig"),
            VocabularyPair(english: "fifty", german: "Fünfzig"),
            VocabularyPair(english: "sixty", german: "Sechzig"),
            VocabularyPair(english: "seventy", german: "Siebzig"),
            VocabularyPair(english: "eighty", german: "Achtzig"),
            VocabularyPair(english: "ninety", german: "Neunzig"),
            VocabularyPair(english: "a hundred", german: "Einhundert")
        ]
    )

    public static let unit5FreeTimePart1 = VocabularyUnit(
        classNumber: 3,
        unitNumber: "5.1",
        title: "Free time (part 1)",
        deadlineDay: "Freitag",
        pairs: [
            VocabularyPair(english: "sail a boat", german: "ein Boot segeln"),
            VocabularyPair(english: "ride a bike", german: "Fahrrad fahren"),
            VocabularyPair(english: "feed animals", german: "Tiere füttern"),
            VocabularyPair(english: "build a robot", german: "einen Roboter bauen"),
            VocabularyPair(english: "dance", german: "tanzen"),
            VocabularyPair(english: "play with friends", german: "mit Freunden spielen"),
            VocabularyPair(english: "cook", german: "kochen"),
            VocabularyPair(english: "fly a kite", german: "einen Drachen steigen lassen"),
            VocabularyPair(english: "skate", german: "skaten"),
            VocabularyPair(english: "play football", german: "Fußball spielen"),
            VocabularyPair(english: "snorkel", german: "schnorcheln"),
            VocabularyPair(english: "climb", german: "klettern"),
            VocabularyPair(english: "play an instrument", german: "ein Instrument spielen"),
            VocabularyPair(english: "draw", german: "zeichnen"),
            VocabularyPair(english: "swim", german: "schwimmen"),
            VocabularyPair(english: "paint a picture", german: "ein Bild malen")
        ]
    )

    public static let unit5FreeTimePart2 = VocabularyUnit(
        classNumber: 3,
        unitNumber: "5.2",
        title: "Free time (part 2)",
        deadlineDay: "Freitag",
        pairs: [
            VocabularyPair(english: "go on holiday", german: "in den Urlaub fahren"),
            VocabularyPair(english: "do homework", german: "Hausaufgaben machen"),
            VocabularyPair(english: "wash the dishes", german: "das Geschirr spülen"),
            VocabularyPair(english: "help in the kitchen", german: "in der Küche helfen"),
            VocabularyPair(english: "read the newspaper", german: "Zeitung lesen"),
            VocabularyPair(english: "have dinner", german: "zu Abend essen"),
            VocabularyPair(english: "lay the table", german: "den Tisch decken"),
            VocabularyPair(english: "take out the rubbish", german: "den Müll rausbringen"),
            VocabularyPair(english: "work in the garden", german: "im Garten arbeiten"),
            VocabularyPair(english: "write an email", german: "eine E-Mail schreiben")
        ]
    )

    public static let unit6Feelings = VocabularyUnit(
        classNumber: 3,
        unitNumber: 6,
        title: "Feelings",
        deadlineDay: "Freitag",
        pairs: [
            VocabularyPair(english: "angry", german: "wütend"),
            VocabularyPair(english: "sad", german: "traurig"),
            VocabularyPair(english: "tired", german: "müde"),
            VocabularyPair(english: "scared", german: "ängstlich"),
            VocabularyPair(english: "happy", german: "glücklich"),
            VocabularyPair(english: "bored", german: "gelangweilt"),
            VocabularyPair(english: "nervous", german: "nervös"),
            VocabularyPair(english: "excited", german: "aufgeregt"),
            VocabularyPair(english: "relaxed", german: "entspannt")
        ]
    )

    public static let unit8AtHome = VocabularyUnit(
        classNumber: 3,
        unitNumber: 8,
        title: "At home",
        deadlineDay: "Freitag",
        pairs: [
            VocabularyPair(english: "attic", german: "der Dachboden"),
            VocabularyPair(english: "wardrobe", german: "der Kleiderschrank"),
            VocabularyPair(english: "floor", german: "der Fußboden"),
            VocabularyPair(english: "bed", german: "das Bett"),
            VocabularyPair(english: "bathroom", german: "das Badezimmer"),
            VocabularyPair(english: "washbasin", german: "das Waschbecken"),
            VocabularyPair(english: "stairs", german: "die Treppe"),
            VocabularyPair(english: "bedroom", german: "das Schlafzimmer"),
            VocabularyPair(english: "kitchen", german: "die Küche"),
            VocabularyPair(english: "table", german: "der Tisch"),
            VocabularyPair(english: "hall", german: "der Flur"),
            VocabularyPair(english: "sofa", german: "das Sofa"),
            VocabularyPair(english: "lamp", german: "die Lampe"),
            VocabularyPair(english: "living room", german: "das Wohnzimmer")
        ]
    )

    public static let unit1Colours = VocabularyUnit(
        classNumber: 3,
        unitNumber: "1.1",
        title: "colours+in my room (part 1: colours)",
        deadlineDay: "Freitag",
        pairs: [
            VocabularyPair(english: "orange", german: "orange"),
            VocabularyPair(english: "green", german: "grün"),
            VocabularyPair(english: "blue", german: "blau"),
            VocabularyPair(english: "yellow", german: "gelb"),
            VocabularyPair(english: "grey", german: "grau"),
            VocabularyPair(english: "red", german: "rot"),
            VocabularyPair(english: "pink", german: "pink"),
            VocabularyPair(english: "white", german: "weiß"),
            VocabularyPair(english: "black", german: "schwarz"),
            VocabularyPair(english: "brown", german: "braun")
        ]
    )

    public static let unit1Numbers = VocabularyUnit(
        classNumber: 3,
        unitNumber: "1.2",
        title: "numbers (part 2)",
        deadlineDay: "Freitag",
        pairs: [
            VocabularyPair(english: "one", german: "eins"),
            VocabularyPair(english: "two", german: "zwei"),
            VocabularyPair(english: "three", german: "drei"),
            VocabularyPair(english: "four", german: "vier"),
            VocabularyPair(english: "five", german: "fünf"),
            VocabularyPair(english: "six", german: "sechs"),
            VocabularyPair(english: "seven", german: "sieben"),
            VocabularyPair(english: "eight", german: "acht"),
            VocabularyPair(english: "nine", german: "neun"),
            VocabularyPair(english: "ten", german: "zehn")
        ]
    )

    public static let unit1InMyRoom = VocabularyUnit(
        classNumber: 3,
        unitNumber: "1.3",
        title: "in my room (part 3)",
        deadlineDay: "Freitag",
        pairs: [
            VocabularyPair(english: "skateboard", german: "das Skateboard"),
            VocabularyPair(english: "teddy", german: "der Teddy"),
            VocabularyPair(english: "car", german: "das Auto"),
            VocabularyPair(english: "bike", german: "das Fahrrad"),
            VocabularyPair(english: "ball", german: "der Ball"),
            VocabularyPair(english: "plane", german: "das Flugzeug"),
            VocabularyPair(english: "robot", german: "der Roboter")
        ]
    )

    public static let unit2School = VocabularyUnit(
        classNumber: 3,
        unitNumber: 2,
        title: "school",
        deadlineDay: "Freitag",
        pairs: [
            VocabularyPair(english: "book", german: "das Buch"),
            VocabularyPair(english: "chair", german: "der Stuhl"),
            VocabularyPair(english: "desk", german: "der Schreibtisch"),
            VocabularyPair(english: "glue stick", german: "der Klebestift"),
            VocabularyPair(english: "pen", german: "der Füller"),
            VocabularyPair(english: "pencil", german: "der Bleistift"),
            VocabularyPair(english: "pencil case", german: "das Etui"),
            VocabularyPair(english: "rubber", german: "das Radiergummi"),
            VocabularyPair(english: "ruler", german: "das Lineal"),
            VocabularyPair(english: "schoolbag", german: "der Tornister"),
            VocabularyPair(english: "scissors", german: "die Schere"),
            VocabularyPair(english: "window", german: "das Fenster"),
            VocabularyPair(english: "door", german: "die Tür")
        ]
    )

    public static let unit3Animals = VocabularyUnit(
        classNumber: 3,
        unitNumber: 3,
        title: "animals",
        deadlineDay: "Freitag",
        pairs: [
            VocabularyPair(english: "lion", german: "der Löwe"),
            VocabularyPair(english: "fox", german: "der Fuchs"),
            VocabularyPair(english: "rat", german: "die Ratte"),
            VocabularyPair(english: "dog", german: "der Hund"),
            VocabularyPair(english: "monkey", german: "der Affe"),
            VocabularyPair(english: "bird", german: "der Vogel"),
            VocabularyPair(english: "cat", german: "die Katze"),
            VocabularyPair(english: "elephant", german: "der Elefant"),
            VocabularyPair(english: "crocodile", german: "das Krokodil"),
            VocabularyPair(english: "snake", german: "die Schlange"),
            VocabularyPair(english: "bat", german: "die Fledermaus"),
            VocabularyPair(english: "frog", german: "der Frosch"),
            VocabularyPair(english: "hippo", german: "das Nilpferd")
        ]
    )
}
