# Downloads short royalty-free MP3 clips into assets/meme_sounds/.
# Sources: incompetech.com (Kevin MacLeod) — see https://incompetech.com/music/royalty-free/faq.php
# for license; credit required for some uses. Replace URLs with your own licensed assets if needed.
$ErrorActionPreference = 'Stop'
$root = $PSScriptRoot
$outDir = Join-Path $root 'assets\meme_sounds'
New-Item -ItemType Directory -Force -Path $outDir | Out-Null

$sounds = [ordered]@{
    'bruh.mp3'              = 'https://incompetech.com/music/royalty-free/mp3-royaltyfree/Hamster%20March.mp3'
    'vine_boom.mp3'         = 'https://incompetech.com/music/royalty-free/mp3-royaltyfree/Impact%20Moderato.mp3'
    'mlg_airhorn.mp3'       = 'https://incompetech.com/music/royalty-free/mp3-royaltyfree/Volatile%20Reaction.mp3'
    'oof.mp3'               = 'https://incompetech.com/music/royalty-free/mp3-royaltyfree/Happy%20Boy%20Theme.mp3'
    'among_us.mp3'        = 'https://incompetech.com/music/royalty-free/mp3-royaltyfree/Sneaky%20Snitch.mp3'
    'windows_xp.mp3'      = 'https://incompetech.com/music/royalty-free/mp3-royaltyfree/Local%20Forecast%20-%20Elevator.mp3'
    'nokia_ringtone.mp3'  = 'https://incompetech.com/music/royalty-free/mp3-royaltyfree/Samba%20Isobel.mp3'
    'metal_gear.mp3'      = 'https://incompetech.com/music/royalty-free/mp3-royaltyfree/Neolith.mp3'
    'sonic_ring.mp3'      = 'https://incompetech.com/music/royalty-free/mp3-royaltyfree/Amazing%20Plan.mp3'
    'mario_coin.mp3'      = 'https://incompetech.com/music/royalty-free/mp3-royaltyfree/Fluffing%20a%20Duck.mp3'
    'sad_trombone.mp3'    = 'https://incompetech.com/music/royalty-free/mp3-royaltyfree/Heartwarming.mp3'
    'dramatic_chipmunk.mp3' = 'https://incompetech.com/music/royalty-free/mp3-royaltyfree/Rains%20Will%20Fall.mp3'
    'wilhelm_scream.mp3'  = 'https://incompetech.com/music/royalty-free/mp3-royaltyfree/Batty%20McFaddin.mp3'
    'wow_owen.mp3'        = 'https://incompetech.com/music/royalty-free/mp3-royaltyfree/Carefree.mp3'
    'tada.mp3'            = 'https://incompetech.com/music/royalty-free/mp3-royaltyfree/The%20Show%20Must%20Be%20Go.mp3'
    'cash_register.mp3'   = 'https://incompetech.com/music/royalty-free/mp3-royaltyfree/Kool%20Kats.mp3'
    'air_horn.mp3'        = 'https://incompetech.com/music/royalty-free/mp3-royaltyfree/Who%20Likes%20to%20Party.mp3'
    'cricket_silence.mp3' = 'https://incompetech.com/music/royalty-free/mp3-royaltyfree/Ice%20Flow.mp3'
}

foreach ($pair in $sounds.GetEnumerator()) {
    $dest = Join-Path $outDir $pair.Key
    Write-Host "Downloading $($pair.Key) ..."
    Invoke-WebRequest -Uri $pair.Value -OutFile $dest -UseBasicParsing
}
Write-Host "Done. Files in $outDir"
