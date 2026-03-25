enum Strings {
    static func get(_ key: String, language: GameLanguage) -> String {
        table[key]?[language] ?? table[key]?[.english] ?? key
    }

    private static let table: [String: [GameLanguage: String]] = [
        "gameOver": [
            .english: "Game Over",
            .french: "Game Over",
            .spanish: "Game Over",
            .portuguese: "Game Over",
        ],
        "paused": [
            .english: "Pause",
            .french: "Pause",
            .spanish: "Pausa",
            .portuguese: "Pausa",
        ],
        "newGame": [
            .english: "New game?",
            .french: "Nouvelle partie ?",
            .spanish: "¿Nueva partida?",
            .portuguese: "Novo jogo?",
        ],
        "currentGameLost": [
            .english: "Your current game will be lost.",
            .french: "La partie en cours sera perdue.",
            .spanish: "Tu partida actual se perderá.",
            .portuguese: "O jogo atual será perdido.",
        ],
        "cancel": [
            .english: "Cancel",
            .french: "Annuler",
            .spanish: "Cancelar",
            .portuguese: "Cancelar",
        ],
        "restart": [
            .english: "Restart",
            .french: "Relancer",
            .spanish: "Reiniciar",
            .portuguese: "Reiniciar",
        ],
        "profile": [
            .english: "Profile",
            .french: "Profil",
            .spanish: "Perfil",
            .portuguese: "Perfil",
        ],
        "allStars": [
            .english: "Monthly Stars",
            .french: "Monthly Stars",
            .spanish: "Monthly Stars",
            .portuguese: "Monthly Stars",
        ],
        "displayedOnAllStars": [
            .english: "Displayed on Monthly Stars.",
            .french: "Affiché dans Monthly Stars.",
            .spanish: "Mostrado en Monthly Stars.",
            .portuguese: "Exibido no Monthly Stars.",
        ],
        "username": [
            .english: "Username",
            .french: "Pseudo",
            .spanish: "Usuario",
            .portuguese: "Usuário",
        ],
        "linkOptional": [
            .english: "Link (optional)",
            .french: "Lien (optionnel)",
            .spanish: "Enlace (opcional)",
            .portuguese: "Link (opcional)",
        ],
        "save": [
            .english: "Save",
            .french: "Enregistrer",
            .spanish: "Guardar",
            .portuguese: "Salvar",
        ],
        "aboutCapelo": [
            .english: "About Capelo",
            .french: "À propos de Capelo",
            .spanish: "Sobre Capelo",
            .portuguese: "Sobre Capelo",
        ],
        "aboutDescription": [
            .english: "Find words, earn time, trigger bombs. Add a link to your profile to get noticed on the monthly leaderboard.",
            .french: "Trouvez des mots, gagnez du temps, déclenchez des bombes. Ajoutez un lien à votre profil pour vous faire connaître dans le classement mensuel.",
            .spanish: "Encuentra palabras, gana tiempo, activa bombas. Añade un enlace a tu perfil para darte a conocer en la clasificación mensual.",
            .portuguese: "Encontre palavras, ganhe tempo, detone bombas. Adicione um link ao seu perfil para se destacar no ranking mensal.",
        ],
        "followTwitter": [
            .english: "Twitter",
            .french: "Twitter",
            .spanish: "Twitter",
            .portuguese: "Twitter",
        ],
        "tryPinpin": [
            .english: "Pinpin",
            .french: "Pinpin",
            .spanish: "Pinpin",
            .portuguese: "Pinpin",
        ],
        "tryGribli": [
            .english: "Gribli",
            .french: "Gribli",
            .spanish: "Gribli",
            .portuguese: "Gribli",
        ],
        "noScoresYet": [
            .english: "No scores yet",
            .french: "Aucun score",
            .spanish: "Sin puntuaciones",
            .portuguese: "Sem pontuações",
        ],
        "play": [
            .english: "Play",
            .french: "Jouer",
            .spanish: "Jugar",
            .portuguese: "Jogar",
        ],
        "word": [
            .english: "word",
            .french: "mot",
            .spanish: "palabra",
            .portuguese: "palavra",
        ],
        "words": [
            .english: "words",
            .french: "mots",
            .spanish: "palabras",
            .portuguese: "palavras",
        ],
        "language": [
            .english: "Language",
            .french: "Langue",
            .spanish: "Idioma",
            .portuguese: "Idioma",
        ],
        "swipeToPlay": [
            .english: "Swipe",
            .french: "Swipe",
            .spanish: "Swipe",
            .portuguese: "Swipe",
        ],
        "tapToDefine": [
            .english: "Tap for definition",
            .french: "Tap pour la définition",
            .spanish: "Tap para la definición",
            .portuguese: "Tap para a definição",
        ],
        "noDefinition": [
            .english: "No definition found",
            .french: "Aucune définition trouvée",
            .spanish: "Sin definición",
            .portuguese: "Sem definição",
        ],
    ]
}
