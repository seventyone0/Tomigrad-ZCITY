AddCSLuaFile("shared.lua")
AddCSLuaFile("cl_init.lua")
include("shared.lua")

local CUSTOM_EXPLOSION_SOUNDS = {
	"explosions/explode3.wav",
	"explosions/explode4.wav",
	"explosions/explode5.wav"
}

local CUSTOM_EXPLOSION_PITCH_MIN = 90
local CUSTOM_EXPLOSION_PITCH_MAX = 110
local CUSTOM_EXPLOSION_VOLUME = 1
local CUSTOM_EXPLOSION_LEVEL = 140

local BLAST_RADIUS_MULT = 1
local BLAST_DAMAGE = 300
local KNOCKBACK_FORCE = 50000
local LIFT_FORCE = 25000


function ENT:Initialize()
	self:SetModel(self.Model)

	self:SetSolid(SOLID_VPHYSICS)
	self:PhysicsInit(SOLID_VPHYSICS)
	self:SetMoveType(MOVETYPE_VPHYSICS)
	self:SetCollisionGroup(COLLISION_GROUP_NONE)
	self:SetUseType(SIMPLE_USE)

	local phys = self:GetPhysicsObject()

	if IsValid(phys) then
		phys:SetMass(self.Mass or 500)
		phys:Wake()
	end

	self:SetSkin(0)

	self.CurLife = self.Life or 50

	self.Armed = false
	self.Arming = false
	self.Exploded = false

	self.Attacker = IsValid(self.GBOWNER) and self.GBOWNER or self
end


function ENT:Arm()
	if self.Exploded or self.Armed or self.Arming then return end

	self.Arming = true

	if self.ArmDelay and self.ArmDelay > 0 then
		timer.Simple(self.ArmDelay, function()
			if IsValid(self) then
				self:ArmInternal()
			end
		end)
	else
		self:ArmInternal()
	end
end


function ENT:ArmInternal()
	if self.Exploded or self.Armed then
		self.Arming = false
		return
	end

	self.Armed = true
	self.Arming = false

	if isstring(self.ArmSound) and self.ArmSound ~= "" then
		self:EmitSound(self.ArmSound)
	end
end


function ENT:BuildProfile()
	local function pick(value)
		if istable(value) then
			return table.Random(value)
		end

		return value
	end

	return {
		Decal = self.Decal,
		Trace = self.TraceLength,
		Effect = self.Effect,
		EffectAir = self.EffectAir,
		EffectWater = self.EffectWater,
		Sound = pick(self.ExplosionSound),
		FarSound = pick(self.FarExplosionSound),
		WaterSound = pick(self.WaterSound),
		WaterFarSound = pick(self.WaterFarSound),
		Force = self.PhysForce,
		Lift = self.PhysLift
	}
end


function ENT:Explode(pos)
	if self.Exploded then return end

	self.Exploded = true

	local explosionPos

	if isvector(pos) then
		explosionPos = Vector(pos)
	else
		explosionPos = self:GetPos() + self:OBBCenter()
	end

	if not util.IsInWorld(explosionPos) then
		self:Remove()
		return
	end

	local owner = IsValid(self.Attacker) and self.Attacker or self



	if self:WaterLevel() > 0 then
		local effectData = EffectData()

		effectData:SetOrigin(explosionPos)
		effectData:SetScale(400)
		effectData:SetNormal(-self:GetAngles():Forward())

		util.Effect("eff_jack_genericboom", effectData, true, true)
	else
		ParticleEffect(
			"pcf_jack_airsplode_small3",
			explosionPos,
			Angle(0, 0, 0)
		)
	end



	local explosionSound =
		CUSTOM_EXPLOSION_SOUNDS[math.random(#CUSTOM_EXPLOSION_SOUNDS)]

	EmitSound(
		explosionSound,
		explosionPos,
		self:EntIndex(),
		CHAN_STATIC,
		CUSTOM_EXPLOSION_VOLUME,
		CUSTOM_EXPLOSION_LEVEL,
		0,
		math.random(
			CUSTOM_EXPLOSION_PITCH_MIN,
			CUSTOM_EXPLOSION_PITCH_MAX
		)
	)

	if self:WaterLevel() > 0 then
		self:EmitSound(
			self.WaterSound or "iedins/water/ied_water_detonate_01.wav",
			140,
			85,
			1,
			CHAN_WEAPON
		)
	else
		local snd = self.ExplosionSound

		if istable(snd) then
			snd = snd[math.random(#snd)]
		end

		if snd then
			self:EmitSound(
				snd,
				145,
				85,
				1,
				CHAN_WEAPON
			)
		end

		local farSound = self.FarExplosionSound

		if istable(farSound) then
			farSound = farSound[math.random(#farSound)]
		end

		if farSound then
			self:EmitSound(
				farSound,
				140,
				85,
				0.9,
				CHAN_WEAPON
			)
		end
	end



	util.ScreenShake(
		explosionPos,
		35,
		200,
		1,
		1000
	)



	local radius =
		(self.ExplosionRadius or 1000) * BLAST_RADIUS_MULT

	local damage =
		self.ExplosionDamage or BLAST_DAMAGE

	util.BlastDamage(
		self,
		owner,
		explosionPos,
		radius,
		damage
	)



	for _, ent in ipairs(ents.FindInSphere(explosionPos, radius)) do
		if not IsValid(ent) then continue end

		local entPos = ent:WorldSpaceCenter()

		local direction = entPos - explosionPos
		local distance = direction:Length()

		if distance <= 0 then
			direction = Vector(0, 0, 1)
			distance = 1
		else
			direction:Normalize()
		end

		local fraction = math.Clamp(
			1 - distance / radius,
			0,
			1
		)

		if fraction <= 0 then continue end



		if hg and hg.ExplosionTrace then
			local trace = hg.ExplosionTrace(
				explosionPos,
				entPos,
				{self}
			)

			if trace.Entity ~= ent then
				continue
			end
		end


		-- Player ragdoll force
		if ent:IsPlayer() then
			local force =
				direction * KNOCKBACK_FORCE * fraction

			force.z =
				force.z +
				LIFT_FORCE * fraction

			if hg and hg.AddForceRag then
				hg.AddForceRag(
					ent,
					0,
					force * 0.5,
					0.5
				)

				hg.AddForceRag(
					ent,
					1,
					force * 0.5,
					0.5
				)
			end

			if hg and hg.LightStunPlayer then
				hg.LightStunPlayer(ent)
			end
		end


		-- Physics props
		local phys = ent:GetPhysicsObject()

		if IsValid(phys) then
			local force =
				direction * KNOCKBACK_FORCE * fraction

			force.z =
				force.z +
				LIFT_FORCE * fraction

			phys:ApplyForceCenter(force)
		end
	end



	local effectData = EffectData()

	effectData:SetOrigin(explosionPos)
	effectData:SetScale(1.2)

	util.Effect(
		"eff_jack_hmcd_shrapnel",
		effectData,
		true,
		true
	)



	self:SetNoDraw(true)
	self:SetNotSolid(true)
	self:SetMoveType(MOVETYPE_NONE)

	local phys = self:GetPhysicsObject()

	if IsValid(phys) then
		phys:EnableMotion(false)
	end

	SafeRemoveEntityDelayed(self, 0.1)
end


function ENT:PhysicsCollide(data, phys)
	if self.Exploded then return end

	if not data then return end

	local speed = data.Speed or 0

	if speed < (self.ImpactSpeed or 200) then
		return
	end

	if not self.Armed then
		if not self.Arming then
			self:Arm()

			-- Wait for the arming delay, then explode.
			timer.Simple(self.ArmDelay or 0, function()
				if not IsValid(self) then return end
				if self.Exploded then return end

				if self.Armed and self.ShouldExplodeOnImpact then
					self:Explode(data.HitPos)
				end
			end)
		end

		return
	end

	-- Already armed.
	if self.ShouldExplodeOnImpact then
		self:Explode(data.HitPos)
	end
end


function ENT:OnTakeDamage(dmginfo)
	if self.Exploded then return end

	local inflictor = dmginfo:GetInflictor()

	if IsValid(inflictor) and inflictor.IsRemBomb then
		return
	end

	self:TakePhysicsDamage(dmginfo)

	if not self.Armed then
		if not self.Arming then
			self:Arm()
		end

		return
	end

	self.CurLife =
		(self.CurLife or 50) -
		dmginfo:GetDamage()

	if self.CurLife <= 0 then
		self.CurLife = self.Life or 50

		timer.Simple(math.Rand(0.05, 0.25), function()
			if IsValid(self) and not self.Exploded then
				self:Explode()
			end
		end)
	end
end


function ENT:Use(activator, caller)
	if self.Exploded or self.Armed or self.Arming then
		return
	end

	if IsValid(activator) and activator:IsPlayer() then
		self:Arm()
	end
end


function ENT:OnRemove()
	self:StopParticles()
end