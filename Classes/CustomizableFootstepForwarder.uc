class CustomizableFootstepForwarder extends Actor;

#exec texture import file=Textures\i_cursedimage.pcx name=i_cursedimage group=Icons mips=Off flags=2

// in 227j this would be a map<Texture,array<Sound>> but in 227i we can't
struct TextureSoundCombo {
  var Texture texture;
  var int cachedSoundSize;
  var int cachedLandingSize;
  var array<Sound> sounds;
  var array<Sound> landingSounds;
};

var int cachedComboSize;
var() array<TextureSoundCombo> textureSoundCombos;

/*
The editor also can't properly handle setting values to arrays of structs...
setting through default properties would work just fine however.

However some people might like to set default properties through the editor.
Below is a workaround. Make sure that the length of 
workaroundSounds == sum of soundsPerTexture
landingSounds == sum of landingSoundsPerTex
and that also
array_size(workaroundTextures) == array_size(soundsPerTexture)
array_size(workaroundTextures) == array_size(landingSoundsPerTexture)

If textureSoundCombos is empty, then the workaround will be loaded instead.
 */
var(EditorGUIWorkaround) array<Texture> textures;
var(EditorGUIWorkaround) array<int> footstepSoundsPerTexture;
var(EditorGUIWorkaround) array<Sound> footstepSounds;
var(EditorGUIWorkaround) array<int> landingSoundsPerTexture;
var(EditorGUIWorkaround) array<Sound> landingSounds;

var bool isOn227jOrNewer;

replication {
  reliable if (Role == ROLE_Authority)
    textureSoundCombos, textures, footstepSoundsPerTexture, footstepSounds, landingSoundsPerTexture, landingSounds, isOn227jOrNewer;
}

simulated function postBeginPlay() {
  log("Setting up custom footsteps...");
  if (!appendToDefaults(validateWorkaround(textures, footstepSoundsPerTexture, footstepSounds, landingSoundsPerTexture, landingSounds))) {
    warn("Custom footsteps have failed validation. Mapper to resolve issue...");
  }
  if (int(level.engineVersion) >= 227 && int(level.EngineSubVersion) >= 10) {
    isOn227jOrNewer = true;
  }
}

simulated function bool appendToDefaults(array<TextureSoundCombo> combosToAppend) {
  local int i,j;
  if (array_size(combosToAppend) == 0) return false;
  j = array_size(textureSoundCombos);
  for (i = 0; i < array_size(combosToAppend); i++) {
    textureSoundCombos[j++] = combosToAppend[i];
  }
  cachedComboSize = j;
  return true;
}

simulated static function array<TextureSoundCombo> validateWorkaround(array<Texture> textures, array<int> soundsPerTex, array<Sound> sounds, array<int> landingSoundsPerTex, array<Sound> landingSounds2) {
  local int i, j, k, l;
  local array<TextureSoundCombo> combos;
  if (array_size(textures) != array_size(soundsPerTex)) return combos;
  for (i = 0; i < array_size(soundsPerTex); i++) j += soundsPerTex[i];
  if (array_size(sounds) != j) return combos;
  j = 0;
  if (array_size(landingSoundsPerTex) != array_size(textures)) return combos;
  for (i = 0; i < array_size(landingSoundsPerTex); i++) j += landingSoundsPerTex[i];
  if (array_size(landingSounds2) != j) return combos;
  for (i = 0; i < array_size(textures); i++) {
    combos[i].texture = textures[i];
    combos[i].cachedSoundSize = soundsPerTex[i];
    combos[i].cachedLandingSize = landingSoundsPerTex[i];
    for (j = 0; j < soundsPerTex[i]; j++) combos[i].sounds[j] = sounds[k++];
    for (j = 0; j < landingSoundsPerTex[i]; j++) combos[i].landingSounds[j] = landingSounds2[l++];
  }
  return combos;
}

// Pick a random footstep sound slot from the texture.
simulated function Sound getSoundForTexture(Texture texture) {
  local int i;
  //local array<Sound> sounds;

  //if (array_size(textureSoundCombos) == 0) textureSoundCombos = validateWorkaround(textures, footstepSoundsPerTexture, footstepSounds, landingSoundsPerTexture, landingSounds);

  for (i = 0; i < cachedComboSize; i++) {
    if (textureSoundCombos[i].texture == texture) {
      //sounds = textureSoundCombos[i].sounds;
      break;
    }
  }

  if (textureSoundCombos[i].cachedSoundSize == 0) return none;
  else return textureSoundCombos[i].sounds[rand(textureSoundCombos[i].cachedSoundSize)];
}

// Pick a random landing sound slot from the texture.
function Sound getLandingSoundForTexture(Texture texture) {
  local int i;
  //local array<Sound> sounds;

  //if (array_size(textureSoundCombos) == 0) textureSoundCombos = validateWorkaround(textures, footstepSoundsPerTexture, footstepSounds, landingSoundsPerTexture, landingSounds);

  for (i = 0; i < cachedComboSize; i++) {
    if (textureSoundCombos[i].texture == texture) {
      //sounds = textureSoundCombos[i].landingSounds;
      break;
    }
  }

  if (textureSoundCombos[i].cachedLandingSize == 0) return none;
  else return textureSoundCombos[i].landingSounds[rand(textureSoundCombos[i].cachedLandingSize)];
}


event drawEditorSelection(Canvas c) {
  level.footprintManager = class'CustomizableFootstepManager';
}

defaultproperties {
  texture=Texture'i_cursedimage'
  bHidden=true
  bEditorSelectRender=true
  bNoDelete=true // thanks to Slade & Bleeder91 for this, I spent so many hours trying to figure out replciation and yet somehow never thought to simply have it not replicated at all
  bAlwaysRelevant=true
}