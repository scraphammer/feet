//=============================================================================
// CustomizableFootstepManager.
//=============================================================================
class CustomizableFootstepManager expands FootStepManager;

simulated static function bool overrideFootstep(Pawn other, out Sound step, out byte wetSteps) {
  local vector start;
  local Texture hitTexture;
  local CustomizableFootstepForwarder forwarder;

  foreach other.allactors(class'CustomizableFootstepForwarder', forwarder) {
    break;
  }

  if (forwarder == none) {
    warn("Failed to get CustomizableFootstepForwarder or CustomizableFootstepForwarder does not exist");
  }

  start = other.location;
  if (!forwarder.isOn227jOrNewer) { 
    start.z-=(other.collisionHeight-2); 
  }
  if(other.traceSurfHitInfo(start,start-vect(0,0,30),,,hitTexture)) {
    step = forwarder.getSoundForTexture(hitTexture);
    if (step != none) return true;
  }

  return super.overrideFootstep(other, step, wetSteps);  
}

static function playLandingNoise(Pawn other, float volAmp, float impactVel) {
  local int i;
  local Sound sound;
  local vector start;
  local Texture hitTexture;
  local CustomizableFootstepForwarder forwarder;

  foreach other.allactors(class'CustomizableFootstepForwarder', forwarder) {
    break;
  }

  if (forwarder == none) {
    warn("Failed to get CustomizableFootstepForwarder or CustomizableFootstepForwarder does not exist");
  }

  start = other.location;
  if (!forwarder.isOn227jOrNewer) { 
    start.z-=(other.collisionHeight-2); 
  }

  if (!other.traceSurfHitInfo(start,start-vect(0,0,30),,,hitTexture)) {
    super.playLandingNoise(other, volAmp, impactVel);
    return;
  }

  for (i = 0; i < forwarder.cachedComboSize; i++) {
    if (forwarder.textureSoundCombos[i].texture == hitTexture) {
      sound = forwarder.getLandingSoundForTexture(hitTexture);
      break;
    }
  }

  if (sound == none) super.playLandingNoise(other, volAmp, impactVel);
  else other.PlaySound(sound,SLOT_Interact,FClamp((4+VolAmp*0.5f) * ImpactVel,0.5,5+VolAmp), false,1000, 1.0);
}