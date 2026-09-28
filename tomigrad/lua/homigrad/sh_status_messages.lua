
local allowedchars = {
	"ah",
	"AХ",
	"гххх",
	"ГХ",
	"AХХХ",
}

local audible_pain = {
	"AAAAAГХ..СУКА.. ОНО БОЛИТ.",
	"Я БОЛЬШЕ НЕ МОГУ ТЕРПЕТЬ!",
    "Сделай чтобы оно остановилось, чтобы ОСТАНОВИЛОСЬ, ЧТОБЫ ОСТАНОВИЛОСЬ",
    "Why won't IT STOP",
    "Можно я отключусь, пожалуйста.",
    "Почему я был рожден чтобы чувствовать это...",
    "Я сделаю все чтобы остановить эту боль... ВСЕ.",
    "Это не жизнь это МУЧЕНИЯ",
    "Мне уже все равно просто ОСТАНОВИ эту БОЛЬ",
    "Ничего не имеет значения кроме ОСТАНОВКИ ЭТОЙ БОЛИ...",
    "Каждая секунда это вечность БОЛИ.",
    "СМЕРТЬ БЫЛА БЫ СЕЙЧАС ПОМИЛОВАНИЕМ...",
    "Только один момент без боли..",
	"БЫЛО БЫ У МЕНЯ С СОБОЙ ОБЕЗБОЛИВАЮЩИЕ. СУКА.",
}

local sharp_pain = {
	"AAAХХ",
	"AAAХ",
	"AAааAХ",
	"AAaaAХ",
	"AAAaaAAAГХ",
	"AAaaAХ",
	"AAaAaaХ",
	"AAAAAaaХ",
	"AAaaAХХХХ",
	"AAaAA",
	"AAAAAa",
	"AAAAaAAAaaaaгхх",
	"AAAaaAa",
	"AaaAAaгхф",
	"aaAaaAaфф",
	"aaaххх",
	"AAAaaГХХХ",
	"AAAaaAAХХ",
	"AAAaaAAAAAaГХХХХ",
	"AAAaaAAAAAaГХАААГХХ",
	"AAAaaAAAAAaГХХAAAAAAХХ",
	"AAAaaAAAAAaГХХХХ",
	"AAAaaAAAaaAAAaГХХХХ",
	"AAAaaAAAaaAAAaAAAAAAAГХХХХ",
	"AAAaaAAAAAaГХХХХ",
	"AAAaaAAAAAAAAAХХХ",
	"AAAaaAAAAAaГHAaaaХХ",
	"AAAaaAAAAAaAaaaaaAAAAХХ",
	"AAAaaAAAAAaAAAAAAAAДГХХХ",
	"AAAaaAAAaaAAAaAAAAAAAAAAAAГГГГГГАГХХХ",
	"AAAaaAAAaaAAAaAAAAAAAAAAAAAAAAAAХ",
}

hg.sharp_pain = sharp_pain

local random_phrase = {
	"Тут достаточно холодно...",
	"Все кажется слишком тихим...",
	"Дыхание кажется достаточно приятным.",
	"А что если эта тишина продлится вечность?",
	"Почему ничего не происходит?",
	"Я чувствую свое сердцебиение...",
	"Тишина почти делает меня глухим.",
	"Время ощущается... как-то по другому.",
	"Тут вообше кто-то есть?",
	"Как долго я тут стоял?",
	"Воздух как-будто металлический.",
	"Я не помню как сюда попал.",
	"Ничего никогда не менятся, или меняется?",
	"Не сон ли это?",
	"Тень как-будто глубже чем обычно.",
	"Мои мысли такие громкие в этой тишине.",
	"Когда стало так темно?",
	"Мне кажется что за мной кто-то наблюдает.",
	"Все на своих местах.",
	"Кто-то знает что я тут?",
	"Стены кажутся ближе каким-то образом.",
	"О чем я думал?",
	"Время тут так странно двигается.",
	"Я не помню когда в последний раз что-то менялось.",
	"Тишина начинает казаться живой.",
}


local fear_hurt_ironic = {
	"Я уверен что в этом есть какой-то урок... если я выживу.",
	"Мой будущий биографер не поверит в этот момент.",
	"Чтож, это тупой способ умереть.",
	"Хотя бы моя жизнь не была скучной.",
	"Записка себе: Никогда не делать это снова.",
	"Это не самый плохой день чтобы умереть.",
	"Это хорошо. Все хорошо.",
	"Я хотя-бы умру зная что был прав.",
	"Думаю что получаю то что заслужил.",
	"Чтож, я хотел приключений.",
	"Они наверно будут смеяться на моих похоронах.",
	"Это хотя бы будет хорошая история... если я выживу чтобы ее рассказать.",
	"Я выживал намного хуже... наверно.",
}

local fear_phrases = {
	"Это не так плохо... правда?",
	"Я не хочу так умирать.",
	"Все правда так закончится?",
	"Это плохо.",
	"Все и правда так заночится?",
	"Я не хочу умирать вот так.",
	"Хотелось бы иметь выход из этой ситуации.",
	"Я жалею о многих вещах.",
	"Это не может быть оно.",
	"Не могу поверить что это происходит со мной.",
	"Я должен был отнестись к этому серьезнее.",
	"Что если я не выживу..?",
	"Это хуже чем я думал.",
	"Это так нечестно.",
	"Я не могу пока сдаться.",
	"Никогда не думал что все будет именно так.",
	"Надо было довериться своим инстинктам.",
	"Дыши. Просто дыши",
	"Холодные руки. Прямые руки.",
}

local is_aimed_at_phrases = {
    "О боже. Это правдо конец.",
    "Не. двигайся.",
    "Это правда как я умру?",
    "Я должен был бежать, почему я просто не убежал?",
    "Пожалуйста не нажимай на курок. Пожалуйста...",
    "Я могу видеть их палец на курке.",
    "Я не хочу умирать. Точно не так.",
    "Если я попрошу пощады, сделаю ли я хуже..?",
    "Это не реально. Это не реально.",
    "Кто-нибудь помогите. Пожалуйста. Кто-нибудь.",
    "Я не хочу умирать в этом месте.",
    "Я не хочу чтобы мои последние мысли были страх.",
    "Я не хочу умирать...",
}

local near_death_poetic = {
	"Пытаюсь встать... но просто не могу...",
	"Дыхание это попытка выжить...",
	"Я не могу точно сказать открыты ли мои глаза...",
	"Последнее что я попробую это вкус моей крови и меди.",
	"Глаза продолжают закрываться.",
	"Не могу вспомнить как стоять.",
	"Эхо в моем черепе.",
	"Когда моргаешь слишком долго не можешь проснуться.",
	"Пальцы не работают как надо.",
	"Легкие отказываются быть полными.",
	"Жалеть о чем-то уже бесполезно.",
}

local near_death_positive = {
	"Я не хочу умирать.",
	"Мне надо выжить.",
	"Все еще есть шанс.",
	"Я не могу дать страху выиграть.",
	"Еще одна попытка.",
	"Я отказываюсь тут умирать.",
	"Хорошо... просто надо подумать.",
	"Просто быть на месте. Движения делают еще хуже.",
	"Дыши медленно. Паника не спасет.",
	"Это не кончено пока это не кончено.",
	"Боль просто сигнал. Игнорируй ее.",
	"Если я умру... то хотя бы это будет быстро.",
	"Я выживал намного хуже. наверно.",
	"Это не как я себе представлял смерть.",
}

local broken_limb = {
	"СУКА. СУКА. ОНО ТОЧНО СЛОМАНО!",
	"Я ЧУВСТВУЮ КАК КУСОЧКИ КОСТИ ДВИГАЮТСЯ!",
	"ОНО СУКА СЛОМАНО. Я ДУМАЮ..",
	"Оно болит даже думая об этом. Точно сломано.",
	"Я не думаю что оно должно так сгибаться.",
	"Ох сука, оно сломалось.",
	"Я не вижу открытого перелома, но чувствую что что-то сломал",
}

local dislocated_limb = {
	"Да оно так не должно сгибаться.",
	"Я должен вправить эту конечность.",
	"Нет... Я должен ее вправить.",
	"Оно просто очень сильно болит. Мне надо к доктору.",
	"Моя конечность не на месте.",
}

local hungry_a_bit = {
    "Мгх, Я голоден...",
    "Чуть чуть еды было бы хорошо...",
    "Я голоден...",
    "Мне надо что-то съесть.",
}

local very_hungry = {
    "Мой живот... Угх...",
    "Если я не поем, мне будет еще хуже...",
    "Живот... блин... я чувствую себя плохо",
}

local after_unconscious = {
    "Что произошло? Оно болит...",
	"Где я? Почему все болит...",
	"I-I thought I was going to die...",
	"Моя голова... Что произошло?",
	"Я почти умер?",
	"Чувство как-будто умер.",
	"Небеса меня не забрали?",
	"Охх-Сука... моя голова болит...",
	"Будет сложно сейчас встать... но мне надо...",
	"Я совсем не помню это место... или помню?",
	"Я никогда больше не хочу это испытывать...",
}

local slight_braindamage_phraselist = {
	"Я не понимаю...",
	"Почему это не понятно...",
	"Где я?",
	"Что? Что это..?",
	"Я не знаю что происходит...",
	"Привет?",
	"Угхххх охххх...      что...",
	"Что... происходит?",
}

local braindamage_phraselist = {
	"Глддеее--.. яяяя?!",
	"Бмеефй... мехк...",
	"Мм--ххх. ммм?",
	"Гмгхх чтт...",
	"Ахггх...мг?",
	"Хгххх... Д-дмддх.",
	"Ллмллмлф, мпп-хфф!",
	"Пооомофффгииии...",
	"Нгхх... гмхх?",
	"Ггггг... Бгхх..",
	"Бритфстаеннххх.",
}

local cold_phraselist = {
	"Становится очень холодно..",
	"Слишком холодно для меня.",
	"Я трясусь, чертов ад, чувак.",
	"Слишком холодно тут..",
	"Надо что-то чтобы подогреться...",
	"Я чувствую себя холодно...",
	"Я как-будто заболел из-за холода, сука."
}

local freezing_phraselist = {
	"Я.. не.. не могу чувствовать с-свое т-ело..",
	"Я не могу.. чув-чувствовать свои ноги...",
	"Я с-сука зам-мерз..",
	"Я-я думма-ю мое лицо оне-мело..",
	"Холодно-о..",
	"Я.. не чувствую ни-че-гоо..",
}

local numb_phraselist = {
	"Больше.. не холодно..",
	"Почему... я чувствую тепло..?",
	"Я думаю все хорошо... Я думаю...",
	"Наконец-то тепло...",
	"Я снова в тепле... Как-то...",
	"Я только что замерзал... Откуда пришло это тепло..?",
}

local hot_phraselist = {
	"Я такой потный..",
	"Это тепло убивает меня..",
	"Моя одежда вся в поте, сука.",
	"Пот лъется из меня. Мне надо остудиться...",
	"Слишком жарко, сука, чувак.",
	"Жара накрывает меня...",
	"Почему тут так жарко?",
}

local heatstroke_phraselist = {
	"МНЕ НУЖНА ВОДА!!",
	"Пожалуйста... воды...",
	"Я чувствую себя плохо... Суука-",
	"МОЯ ГОЛОВА!- Она болит..",
	"Моя голова болит..",
}

local heatvomit_phraselist = {
	"Эта жара..- Меня щас вырвет-",
	"Угхххх-... Меня щас вырвет-",
	"Суууккаа.. Оугхх-.. Я не чувству-"
}

local hg_showthoughts = ConVarExists("hg_showthoughts") and GetConVar("hg_showthoughts") or CreateClientConVar("hg_showthoughts", "1", true, true, "Toggle thoughts of your character", 0, 1)

function string.Random(length)
	local length = tonumber(length)

    if length < 1 then return end

    local result = {}

    for i = 1, length do
        result[i] = allowedchars[math.random(#allowedchars)]
    end

    return table.concat(result)
end

function hg.nothing_happening(ply)
	if not IsValid(ply) then return end

	return ply.organism and ply.organism.fear < -0.6
end

function hg.fearful(ply)
	if not IsValid(ply) then return end

	return ply.organism and ply.organism.fear > 0.5
end

function hg.likely_to_phrase(ply)
	local org = ply.organism

	local pain = org.pain
	local brain = org.brain
	local blood = org.blood
	local fear = org.fear
	local temperature = org.temperature
	local broken_dislocated = org.just_damaged_bone and ((org.just_damaged_bone - CurTime()) < -3)

	return (broken_dislocated) and 5
		or (pain > 65) and 5
		or (temperature < 31 and 0.5)
		or (temperature > 38 and 0.5)
		or (blood < 3000 and 0.3)
		or (fear > 0.5 and 0.7)
		or (brain > 0.1 and brain * 5)
		or (fear < -0.5 and 0.05)
		or -0.1
end

function IsAimedAt(ply)
    return ply.aimed_at or 0
end

local function get_status_message(ply)
	if not IsValid(ply) then
		if CLIENT then
			ply = lply
		else
			return
		end
	end

	local nomessage = hook.Run("HG_CanThoughts", ply) --ply.PlayerClassName == "Gordon" || ply.PlayerClassName == "Combine"
	if nomessage ~= nil and nomessage == false then return "" end

    if ply:GetInfoNum("hg_showthoughts", 1) == 0 then return "" end

	local org = ply.organism
	
	if not org or not org.brain then return "" end

	local pain = org.pain
	local brain = org.brain
	local temperature = org.temperature
	local blood = org.blood
	local hungry = org.hungry
	local broken_dislocated = org.just_damaged_bone and ((org.just_damaged_bone + 3 - CurTime()) < -3)
	local fear = org.fear
	local adrenaline = org.adrenaline

	if broken_dislocated and org.just_damaged_bone then
		org.just_damaged_bone = nil
	end
	
	local broken_notify = (org.rarm == 1) or (org.larm == 1) or (org.rleg == 1) or (org.lleg == 1)
	local dislocated_notify = (org.rarm == 0.5) or (org.larm == 0.5) or (org.rleg == 0.5) or (org.lleg == 0.5)
	local after_unconscious_notify = org.after_otrub

	if not isnumber(pain) then return "" end

	local str = ""

	local most_wanted_phraselist
	
	if temperature < 35 then
		most_wanted_phraselist = temperature > 31 and cold_phraselist or (temperature < 28 and numb_phraselist or freezing_phraselist)
	elseif temperature > 38 then
		most_wanted_phraselist = temperature < 40 and hot_phraselist or heatstroke_phraselist
	end

	if not most_wanted_phraselist and hungry and hungry > 25 and math.random(3) == 1 then
		most_wanted_phraselist = hungry > 45 and very_hungry or hungry_a_bit
	end

	if (blood < 3100) or (pain > 75) or (broken_dislocated) or (broken_notify) or (dislocated_notify) then
		if pain > 75 and (broken_dislocated) then
			most_wanted_phraselist = math.random(2) == 1 and audible_pain or (broken_notify and broken_limb or dislocated_limb)
		elseif pain > 75 then
			most_wanted_phraselist = audible_pain
		elseif broken_dislocated then
			most_wanted_phraselist = (broken_notify and broken_limb or dislocated_limb)
		end

		if pain > 100 then
			most_wanted_phraselist = sharp_pain
		end

		if not most_wanted_phraselist then
			if (broken_dislocated_notify) and (blood < 3100) then
				most_wanted_phraselist = blood < 2900 and (near_death_poetic) or (math.random(2) == 1 and (broken_notify and broken_limb or dislocated_limb) or near_death_poetic)
			--elseif(broken_dislocated_notify)then
				--most_wanted_phraselist = (broken_notify and broken_limb or dislocated_limb)
			elseif(blood < 3100)then
				if adrenaline > 1.3 and fear < 0.5 then
					most_wanted_phraselist = near_death_positive
				else
					most_wanted_phraselist = near_death_poetic
				end
			end
		end
	elseif after_unconscious_notify then
		most_wanted_phraselist = after_unconscious
	elseif hg.nothing_happening(ply) then
		most_wanted_phraselist = random_phrase

		if hungry and hungry > 25 and math.random(5) == 1 then
			most_wanted_phraselist = hungry > 45 and very_hungry or hungry_a_bit
		end
	elseif hg.fearful(ply) then
		most_wanted_phraselist = ((IsAimedAt(ply) > 0.9) and is_aimed_at_phrases or (math.random(10) == 1 and fear_hurt_ironic or fear_phrases))
	end

	if brain > 0.1 then
		most_wanted_phraselist = brain < 0.2 and slight_braindamage_phraselist or braindamage_phraselist
	end
	
	if most_wanted_phraselist then
		str = most_wanted_phraselist[math.random(#most_wanted_phraselist)]

		return str
	else
		return ""
	end
end

local allowedlist_types = {
	heatvomit = heatvomit_phraselist,
}

function hg.get_phraselist(ply, type)
	if not IsValid(ply) then
		if CLIENT then
			ply = lply
		else
			return
		end
	end
	
	local nomessage = ply.PlayerClassName == "Gordon" || ply.PlayerClassName == "Combine"

	if nomessage then return "" end
    if ply:GetInfoNum("hg_showthoughts", 1) == 0 then return "" end

	local org = ply.organism	
	if not org or not org.brain then return "" end

	if not isstring(type) or not allowedlist_types[type] then return "" end

	local needed_list = allowedlist_types[type]

	local str = needed_list[math.random(#needed_list)]
	return str
end

function hg.get_status_message(ply)
	local txt = get_status_message(ply)

	return txt
end
