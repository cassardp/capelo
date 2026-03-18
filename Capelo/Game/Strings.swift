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
        "tapToPause": [
            .english: "tap to pause",
            .french: "toucher pour pauser",
            .spanish: "toca para pausar",
            .portuguese: "toque para pausar",
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
            .english: "All Stars",
            .french: "All Stars",
            .spanish: "All Stars",
            .portuguese: "All Stars",
        ],
        "displayedOnAllStars": [
            .english: "Displayed on All Stars.",
            .french: "Affiché dans All Stars.",
            .spanish: "Mostrado en All Stars.",
            .portuguese: "Exibido no All Stars.",
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
            .english: "Capelo is a minimalist word game. Drag across the grid to form words and chase the high score. Add a link to your profile to showcase your project on the leaderboard.",
            .french: "Capelo est un jeu de mots minimaliste. Glissez sur la grille pour former des mots et visez le meilleur score. Ajoutez un lien à votre profil pour mettre en avant votre projet dans le classement.",
            .spanish: "Capelo es un juego de palabras minimalista. Desliza por la cuadrícula para formar palabras y persigue la puntuación más alta.",
            .portuguese: "Capelo é um jogo de palavras minimalista. Deslize pela grade para formar palavras e busque a maior pontuação.",
        ],
        "followTwitter": [
            .english: "Follow me on Twitter",
            .french: "Suivez-moi sur Twitter",
            .spanish: "Sígueme en Twitter",
            .portuguese: "Siga-me no Twitter",
        ],
        "tryPinpin": [
            .english: "Try Pinpin (my other app)",
            .french: "Essayez Pinpin (mon autre app)",
            .spanish: "Prueba Pinpin (mi otra app)",
            .portuguese: "Experimente Pinpin (meu outro app)",
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
            .english: "Swipe the word to play",
            .french: "Glissez le mot pour jouer",
            .spanish: "Desliza la palabra para jugar",
            .portuguese: "Deslize a palavra para jogar",
        ],
        "noDefinition": [
            .english: "No definition found",
            .french: "Aucune définition trouvée",
            .spanish: "Sin definición",
            .portuguese: "Sem definição",
        ],
    ]
}
