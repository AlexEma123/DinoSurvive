local anim = require 'anim8'
local lg = love.graphics

local estaJogando
local pausado

local personagem
local animPersonagem

local meteoros
local meteoro

local moeda
local moedas

local chao
local larguraTela
local alturaTela

local fonte
local pontuacao

local musicaTema
local meteoroExplosao
local moedaDrop

love.window.setMode(768, 580)
love.window.setTitle("DinoSurvive")

function love.load()
 --Ajustando tamanho da tela e definindo variaveis que comportem seus valores

   larguraTela = lg.getWidth()
   alturaTela = lg.getHeight()

-- Definindo estado de jogo
  estaJogando = false
  pausado = false

--Definindo background do jogo

   background = lg.newImage('assets/imagens/BG.png')

 --Definindo pontuação inicial do jogo
   pontuacao = 0

--Definindo as características dos principais elementos gráficos e interativos do jogo
   chao = {
      imagem = love.graphics.newImage('assets/imagens/2.png'),
      x = 0, y = lg.getHeight() - 128
   }
   personagem = {
     imgs = {parado = lg.newImage('assets/imagens/iddlesp.png'), correndo = lg.newImage('assets/imagens/runsp.png'), pulando = lg.newImage('assets/imagens/jumpsp.png')},
	 imgAtual = '',
     animacaoAtual = '',
	 sons = {pulando = love.audio.newSource('assets/sons/yoshi-wooh.mp3','static'),morrendo =love.audio.newSource('assets/sons/yoshi-waaah.mp3','static')},
	 somAtual='',
	 direcao = true,
	 w = 0.18*680, h = 0.18*420,
	 x = 12, y= chao.y-0.18*420,
     velY = 0,
	 vidas = 3
   }
   meteoro = {
     imgs={caindo=lg.newImage('assets/imagens/meteoro.png'),explosao=lg.newImage('assets/imagens/explosao.png')},
     imgAtual = '',
	 animacaoAtual = '',
	 x=20,y=-100,
     w=0.18*520, h = 0.18*620,
	 colisao = false,
	 contagemRegressiva = 3
   }
   moeda = {
	 img = lg.newImage('assets/imagens/moeda.png'),
	 animacao ='',
	 x='',y='',
	 w='',h='',
	 contagemRegressiva = 2
   }


   meteoros={}
   moedas={}


   --Adicionando animação específica ao personagem

   mudaAnimacao(1)

   --Definições padrão da física básica do jogo

   gravidade = 500
   maxAltura = 300

   --Fonte
   fonte = love.graphics.newFont("assets/fontes/8-bit pusab.ttf", 15)

   --Sons do jogo
   musicaTema = love.audio.newSource("assets/sons/Theme_Song.mp3","static")
   meteoroExplosao = love.audio.newSource("assets/sons/explosao.wav","static")
   moedaDrop = love.audio.newSource("assets/sons/coin1.wav","static")

   --Executando música tema
    musicaTema:play()
	musicaTema:setLooping(true)
end

function love.update(dt)

 local function iniciaJogo()
 --Controla movimentos e animações do personagem principal
   personagemMovimentos(dt)
   personagem.animacaoAtual:update(dt)

--Controla o estado dos meteoros em tela, além de gerar novos
   if meteoro.contagemRegressiva < 0.1 then
     math.randomseed(os.time())

	 table.insert(meteoros, {
       imgs={caindo=lg.newImage('assets/imagens/meteoro.png'),explosao=lg.newImage('assets/imagens/explosao.png')},
       imgAtual = '',
	   animacaoAtual = '',
	   x=math.random(larguraTela-40),y=-100,
       w=0.2*520, h = 0.2*620,
	   colisao = false,
	   contagemMorte = 1
     })
     meteoroAnimacao(1,meteoros[#meteoros])
	 if pontuacao < 100 then
	   meteoro.contagemRegressiva = 3
	 else if pontuacao < 300 then
	   meteoro.contagemRegressiva = 2
	 else if pontuacao < 500 then
	   meteoro.contagemRegressiva = 1
	 else
	   meteoro.contagemRegressiva = 0.8
	 end
	 end
	 end
   else
	 meteoro.contagemRegressiva = meteoro.contagemRegressiva-dt
   end

--Controla o estado das moedas em tela, além de gerar novas
   if moeda.contagemRegressiva < 0.1 then

	 table.insert(moedas, {
        img = lg.newImage('assets/imagens/moeda.png'),
	    x=math.random(larguraTela-40),y=chao.y-0.2*171,
	    w=0.2*191,h=0.2*171,
		duracao = 7
     })
     moedaAnimacao(moedas[#moedas])
     moeda.contagemRegressiva = 1
   else
	 moeda.contagemRegressiva = moeda.contagemRegressiva-dt
   end
--Controla a colisao de meteoros e sua subsequente remoção de tela
   for k, objmeteoro in ipairs(meteoros) do
	  meteoroMovimentos(objmeteoro,dt)
      objmeteoro.animacaoAtual:update(dt)
	  if objmeteoro.colisao then
	    if objmeteoro.contagemMorte > 0.05 then
		  objmeteoro.contagemMorte=objmeteoro.contagemMorte-dt
		else
		  table.remove(meteoros,k)
		end
	  end
   end
--Controla a captura de moedas e sua subsequente remoção de tela
   for k, objmoeda in ipairs(moedas) do
	  objmoeda.animacao:update(dt)
      if objmoeda.duracao < 0 then
	     table.remove(moedas,k)
	  else
	     objmoeda.duracao = objmoeda.duracao - dt
	  end
   end
   meteoroColisoes()
   moedaColisoes()
 end

 if estaJogando and personagem.vidas > 0 and not pausado then
    iniciaJogo()
 end


end


function love.draw()
 local function iniciaPartida()
   --Representa background e chão
   desenhaBackground()
   desenhaChao()

   if pausado then
      lg.setColor(1,2/255,100/255)
      lg.rectangle('fill',320,220,40,100)
	  lg.rectangle('fill',400,220,40,100)
   end

   lg.setColor(255,255,255)

   --Definições da animação do personagem
   if personagem.direcao then
	   personagem.animacaoAtual:draw(personagem.imgAtual, personagem.x, personagem.y, 0,0.18,0.18,57,0)
   else
	   personagem.animacaoAtual:draw(personagem.imgAtual, personagem.x, personagem.y, 0,-0.18,0.18,57,0)
   end

   --definições da animação dos meteoros
   local metPosy
   local dimx, dimy

   for k, objmeteoro in ipairs(meteoros) do
      dimx, dimy = 0.18,0.18
	  metPosy=objmeteoro.y
      if objmeteoro.colisao then

         dimx,dimy = 1.3,1.3
	  end
      objmeteoro.animacaoAtual:draw(objmeteoro.imgAtual, objmeteoro.x, metPosy, 0,dimx,dimy,22,0)
   end
   --definições da animação das moedas
   for k, objmoeda in ipairs(moedas) do
      objmoeda.animacao:draw(objmoeda.img, objmoeda.x, objmoeda.y, 0,0.2,0.2,70,0)
   end

   lg.setColor(1,2/255,100/255)

   lg.setFont(fonte)
   lg.print("Pontuacao : ".. pontuacao, 30, 10)

   local imgCoracao = lg.newImage('assets/imagens/heart.png')
   lg.print("Vidas : ", 500, 10)
   for i = 1, personagem.vidas do
     lg.draw(imgCoracao, 560+(0.5*imgCoracao:getWidth()+8)*i, 10, 0,0.5,0.5,0,0)
   end
   lg.setColor(255,255,255)
 end

 if estaJogando and personagem.vidas > 0 then
    iniciaPartida()
 else if personagem.vidas == 0 then
    lg.setFont(love.graphics.newFont("assets/fontes/8-bit pusab.ttf", 30))
	desenhaBackground()
	lg.draw(lg.newImage('assets/imagens/GameOver.png'), 180, 50, 0, 0.5,0.5, 0,0)
	lg.setColor(1,2/255,100/255)
    lg.print("Game Over",250,60)
	lg.setFont(love.graphics.newFont("assets/fontes/8-bit pusab.ttf", 20))
	lg.print("Pontuacao: ",250,340)
	lg.print(pontuacao,450,340)
	lg.setFont(love.graphics.newFont("assets/fontes/8-bit pusab.ttf", 15))
	lg.print("Aperte ESPACO para voltar ao inicio",140,420)
	lg.setColor(255,255,255)
 else
    lg.setFont(fonte)
	desenhaBackground()
	lg.draw(lg.newImage('assets/imagens/Inicio.png'), 260, 100, 0, 0.5,0.5, 0,0)
	lg.draw(lg.newImage('assets/imagens/Title.png'), 180, 300, 0, 0.8,0.8, 0,0)
	lg.setColor(1,2/255,100/255)
	lg.print("Aperte s para iniciar a partida", 180, 400)
	lg.setColor(255,255,255)
 end
 end
end

function desenhaBackground()
    lg.draw(background, 0, -80)
end

function desenhaChao()
    totalW = 0
    for i = 1, 6 do
     love.graphics.draw(chao.imagem, totalW, lg.getHeight()-128, 0,1,1,0,0)
	 totalW = totalW + chao.imagem:getWidth()
	end
end

function personagemMovimentos(dt)
    if personagem.velY ~= 0 then
	    personagem.y = personagem.y - personagem.velY*dt
		personagem.velY = personagem.velY - gravidade*dt
		if personagem.y > (chao.y-personagem.h) then
		    personagem.velY = 0
			personagem.y = chao.y-personagem.h
			mudaAnimacao(1)
	    end
	end
    if love.keyboard.isDown("right") and (personagem.x+60) < larguraTela then
	    personagem.direcao = true
		personagem.x = personagem.x + 250*dt

	end
	if love.keyboard.isDown("left") and (personagem.x-60) > 0 then
	    personagem.direcao = false
	    personagem.x = (personagem.x) -  250*dt
	end
end

function love.keypressed(key)
	if key == "up" then
	   if personagem.velY == 0 then
	       personagem.somAtual = personagem.sons.pulando
	       personagem.somAtual:stop()
		   personagem.somAtual:play()
	       mudaAnimacao(3)
	       personagem.velY = maxAltura
	   end
	end
	if (key == 'right' and personagemNoChao()) or (key == 'left' and personagemNoChao()) then
       mudaAnimacao(2)
    end
	if (key == 'right' and personagemNoChao()) and (key == 'left' and personagemNoChao()) then
       mudaAnimacao(1)
    end
	if key == 's' then
	  estaJogando = true
	end
	if key == 'p' then
	  pausado = not pausado
	  if pausado then musicaTema:stop() else musicaTema:play() end
	end
	if key == 'space' and personagem.vidas == 0 then
	  musicaTema:stop()
	  love.load()
	end
end

function love.keyreleased(key)
  if key == 'right' or key == 'left' then
    if personagemNoChao() then mudaAnimacao(1) end
  end
end

function personagemNoChao()
    return personagem.y == (chao.y-personagem.h)
end

function estaNaTela()
  return personagem.x > 0 and (personagem.x-60) < lg.getHeight()
end

function mudaAnimacao(n)
   local g
   if n == 1 then
      g = anim.newGrid(680, 420, personagem.imgs.parado:getWidth(), personagem.imgs.parado:getHeight())
      animParado = anim.newAnimation(g('1-10',1),0.04)
      personagem.imgAtual = personagem.imgs.parado
      personagem.animacaoAtual = animParado
   end
   if n == 2 then
      g = anim.newGrid(680, 420, personagem.imgs.correndo:getWidth(), personagem.imgs.correndo:getHeight())
      animRun = anim.newAnimation(g('1-8',1),0.04)
      personagem.imgAtual = personagem.imgs.correndo
      personagem.animacaoAtual = animRun
   end
   if n == 3 then
      g = anim.newGrid(680, 420, personagem.imgs.pulando:getWidth(), personagem.imgs.pulando:getHeight())
      animRun = anim.newAnimation(g('1-12',1),0.125)
      personagem.imgAtual = personagem.imgs.pulando
      personagem.animacaoAtual = animRun
   end
end

function meteoroAnimacao(n, objmeteoro)
   local g
   if n == 1 then
      objmeteoro.imgAtual = objmeteoro.imgs.caindo
      g = anim.newGrid(objmeteoro.imgAtual:getWidth(),objmeteoro.imgAtual:getHeight(),objmeteoro.imgAtual:getWidth(),objmeteoro.imgAtual:getHeight())
      animCaindo = anim.newAnimation(g('1-1',1),0.04)
      objmeteoro.animacaoAtual = animCaindo
   end
   if n == 2 then
      objmeteoro.imgAtual = objmeteoro.imgs.explosao
      g = anim.newGrid(64,64,objmeteoro.imgAtual:getWidth(),objmeteoro.imgAtual:getHeight())
      animCaindo = anim.newAnimation(g('1-5',1,'1-5',2,'1-5',3,'1-5',4,'1-5',5),0.04)
      objmeteoro.animacaoAtual = animCaindo
   end
end

function meteoroMovimentos(objmeteoro,dt)
  if not objmeteoro.colisao then
   if objmeteoro.y > (chao.y-objmeteoro.h+32) then
	  objmeteoro.y = (chao.y-objmeteoro.h+32)
	  meteoroAnimacao(2, objmeteoro)
	  objmeteoro.colisao = true
	  meteoroExplosao:stop()
	  meteoroExplosao:play()
   else if objmeteoro.y < (chao.y-objmeteoro.h+32) then
      objmeteoro.y=objmeteoro.y+250*dt
   end
   end
  end
end

function meteoroColide(objmeteoro)
    -- return (math.abs(personagem.x - (objmeteoro.x)) < (personagem.w-80) and (math.abs(personagem.y-objmeteoro.y)<objmeteoro.h-40)) or ((math.abs((personagem.x-80)-objmeteoro.x) < (objmeteoro.w)) and (math.abs(personagem.y-objmeteoro.y)<objmeteoro.h-40))
    return (((personagem.x - objmeteoro.x ) > (-1)*(personagem.w-80) and (personagem.x - (objmeteoro.x))<(objmeteoro.w+20)) and  math.abs(personagem.y-objmeteoro.y)<objmeteoro.h-40)
end

function meteoroColisoes()
   for k, objmeteoro in ipairs (meteoros) do
     if not objmeteoro.colisao then
      if meteoroColide(objmeteoro) then
		objmeteoro.colisao = true
		meteoroAnimacao(2, objmeteoro)
		meteoroExplosao:stop()
		meteoroExplosao:play()
		personagem.vidas = personagem.vidas - 1
		personagem.somAtual = personagem.sons.morrendo
		personagem.somAtual:stop()
		personagem.somAtual:play()
		personagem.direcao = true
		personagem.x = 12
	  end
	 end
   end
end

function moedaAnimacao(objmoeda)
   g = anim.newGrid(191,171,objmoeda.img:getWidth(),objmoeda.img:getHeight())
   objmoeda.animacao = anim.newAnimation(g('1-6',1),0.08)
end


function moedaColide(objmoeda)
	return (math.abs(personagem.x - objmoeda.x) < (personagem.w-60) and (math.abs(personagem.y-objmoeda.y)<personagem.h)) or ((math.abs((personagem.x-60)-objmoeda.x) < objmoeda.w) and (math.abs(personagem.y-objmoeda.y)<personagem.h))
end

function moedaColisoes()
   for k, objmoeda in ipairs (moedas) do
      if moedaColide(objmoeda) then
		pontuacao = pontuacao + 5
		moedaDrop:stop()
		moedaDrop:play()
		table.remove(moedas, k)
	  end
   end
end
