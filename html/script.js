window.addEventListener('message', function(event) {
    const data = event.data;
    const audioPlayer = document.getElementById('player');

    // Zkontroluje, zda přišla akce 'playSound'
    if (data.action === 'playSound') {
        // Nastaví zdroj zvuku (např. 'sounds/hint.ogg')
        audioPlayer.src = data.soundFile;

        // Nastaví hlasitost (hodnota mezi 0.0 a 1.0)
        audioPlayer.volume = data.volume;

        // Přehraje zvuk
        audioPlayer.play();
    }
});