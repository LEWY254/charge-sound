import 'sound_item.dart';

class MemeSoundCategory {
  final String name;
  final List<SoundItem> sounds;

  const MemeSoundCategory({required this.name, required this.sounds});
}

final memeSoundCategories = [
  MemeSoundCategory(
    name: 'Classic',
    sounds: [
      _meme('bruh', 'Bruh', 1, 'Classic'),
      _meme('vine_boom', 'Vine Boom', 2, 'Classic'),
      _meme('mlg_airhorn', 'MLG Airhorn', 3, 'Classic'),
      _meme('oof', 'Oof', 1, 'Classic'),
      _meme('among_us', 'Among Us', 2, 'Classic'),
    ],
  ),
  MemeSoundCategory(
    name: 'Iconic',
    sounds: [
      _meme('windows_xp', 'Windows XP Start', 4, 'Iconic'),
      _meme('nokia_ringtone', 'Nokia Ringtone', 5, 'Iconic'),
      _meme('metal_gear', 'Metal Gear Alert', 2, 'Iconic'),
      _meme('sonic_ring', 'Sonic Ring', 1, 'Iconic'),
      _meme('mario_coin', 'Mario Coin', 1, 'Iconic'),
    ],
  ),
  MemeSoundCategory(
    name: 'Funny',
    sounds: [
      _meme('sad_trombone', 'Sad Trombone', 3, 'Funny'),
      _meme('dramatic_chipmunk', 'Dramatic Chipmunk', 2, 'Funny'),
      _meme('wilhelm_scream', 'Wilhelm Scream', 2, 'Funny'),
      _meme('wow_owen', 'Wow (Owen Wilson)', 1, 'Funny'),
    ],
  ),
  MemeSoundCategory(
    name: 'Effects',
    sounds: [
      _meme('tada', 'Tada', 2, 'Effects'),
      _meme('cash_register', 'Cash Register', 1, 'Effects'),
      _meme('air_horn', 'Air Horn', 2, 'Effects'),
      _meme('cricket_silence', 'Cricket Silence', 3, 'Effects'),
    ],
  ),
];

List<SoundItem> get allMemeSounds =>
    memeSoundCategories.expand((c) => c.sounds).toList();

SoundItem _meme(String id, String name, int seconds, String category) {
  return SoundItem(
    id: 'meme_$id',
    name: name,
    path: 'assets/meme_sounds/$id.mp3',
    duration: Duration(seconds: seconds),
    source: SoundSource.meme,
    category: category,
  );
}
