class MainVM
	constructor: ->
		@availableUnits = ko.observableArray([
				{text: 'ENG'}
				{text: 'SI'}
			])
		@selectedUnit = ko.observable()
		@longUnit = ko.observable('---')
		@presionUnit = ko.observable('---')
		@tempUnit = ko.observable('---')
		@pesoUnit = ko.observable('---')
		@densidadUnit = ko.observable('---')
		@setRulesValidation()

	calculate: =>
		console.log 'calculatingg'
		$form = $('.ui.form')

		if $form.form('is valid')
			operation = radioRigRel = lxCalc = lyCalc = cxCalc = cyCalc = cLoannides = b = esfuerzoFriccion = radioContacto = 0.0
			canMakeOperation = true

			if $form.form('get value', 'radioContacto')
				radioContacto = parseFloat($form.form('get value', 'radioContacto'))
			else
				if $form.form('get value', 'presionInflado') and $form.form('get value', 'cargaSemiejeII')
					radioContacto = Math.sqrt(parseFloat($form.form('get value', 'cargaSemiejeII'))/(Math.PI*parseFloat($form.form('get value', 'presionInflado'))))
				else
					canMakeOperation = false
					alert("Hay valores vacíos, no se puede hacer el cálculo")

			if canMakeOperation

				espesorLosa = parseFloat($form.form('get value', 'espesorLosa'))
				moduloElasticidad = parseFloat($form.form('get value', 'moduloElasticidad'))
				relacionPoisson = parseFloat($form.form('get value', 'relacionPoisson'))
				moduloReaccion = parseFloat($form.form('get value', 'moduloReaccion'))
				cargaSemieje = parseFloat($form.form('get value', 'cargaSemieje'))
				largoLosaMayor = parseFloat($form.form('get value', 'largoLosaMayor'))
				largoLosaMenor = parseFloat($form.form('get value', 'largoLosaMenor'))
				coeficienteDilatacion = parseFloat($form.form('get value', 'coeficienteDilatacion'))
				coeficienteFriccion = parseFloat($form.form('get value', 'coeficienteFriccion'))
				gradienteTemperatura = parseFloat($form.form('get value', 'gradienteTemperatura'))
				densidadConcreto = parseFloat($form.form('get value', 'densidadConcreto'))
				resistenciaConcreto = parseFloat($form.form('get value', 'resistenciaConcreto'))

				if @selectedUnit() is 'SI'
					espesorLosa *= 0.0393701
					moduloElasticidad *= 145
					moduloReaccion *= (1/0.2713)
					cargaSemieje *= 0.224719101123595
					largoLosaMayor *= 0.393701
					largoLosaMenor *= 0.393701
					densidadConcreto *= 3.685956506
					radioContacto *= 0.393701
					resistenciaConcreto *= 145

				$form.form('set value', 'radioContactoCalc', radioContacto.toFixed(2))

				# Calculando radio rigidez relativa
				radioRigRel = Math.pow((moduloElasticidad * Math.pow(espesorLosa, 3)) / ((1-Math.pow(relacionPoisson, 2))*12*moduloReaccion), 0.25)
				radioRigRel *= 2.54 if @selectedUnit() is 'SI'
				$form.form('set value', 'radioRigRel', radioRigRel.toFixed(2))

				# Calculando esfuerzo de alabaeo
				lxCalc = largoLosaMayor / radioRigRel
				lyCalc = largoLosaMenor / radioRigRel
				cxCalc = @interpolate(lxCalc)
				cyCalc = @interpolate(lyCalc)
				$form.form('set value', 'lx', lxCalc.toFixed(5))
				$form.form('set value', 'ly', lyCalc.toFixed(5))
				$form.form('set value', 'cx', cxCalc.toFixed(5))
				$form.form('set value', 'cy', cyCalc.toFixed(5))

				#	Calculando esfuerzo  de borde
				#	Borde largo
				operation = (cxCalc*moduloElasticidad*coeficienteDilatacion*gradienteTemperatura) / 2
				operation *= (21 / 3045) if @selectedUnit() is 'SI'
				$form.form('set value', 'esfuerzoBordeLargo', operation.toFixed(3))
				#	Borde ancho
				operation = (cyCalc*moduloElasticidad*coeficienteDilatacion*gradienteTemperatura) / 2
				operation *= (21 / 3045) if @selectedUnit() is 'SI'
				$form.form('set value', 'esfuerzoBordeAncho', operation.toFixed(3))

				# Calculo esfuerzo interior
				#	Borde largo
				operation = (moduloElasticidad*coeficienteDilatacion*gradienteTemperatura) * (cxCalc+cyCalc*relacionPoisson) / (2-2*Math.pow(relacionPoisson, 2))
				$form.form('set value', 'esfuerzoInteriorLargo', operation.toFixed(3))
				#	Borde ancho
				operation = (moduloElasticidad*coeficienteDilatacion*gradienteTemperatura) * (cxCalc*relacionPoisson+cyCalc) / (2-2*Math.pow(relacionPoisson, 2))
				operation *= (21 / 3045) if @selectedUnit() is 'SI'
				$form.form('set value', 'esfuerzoInteriorAncho', operation.toFixed(3))

				# Calculo Westergaard
				#   esfuerzo
				operation = (3*cargaSemieje/Math.pow(espesorLosa, 2))*(1-Math.pow(radioContacto*Math.sqrt(2)/radioRigRel, 0.6))
				operation *= (21 / 3045) if @selectedUnit() is 'SI'
				$form.form('set value', "esfuerzoWester", operation.toFixed(2))
				#   deflexion
				operation = (cargaSemieje/(moduloReaccion*Math.pow(radioRigRel, 2)))*(1.1 - 0.88*radioContacto*Math.sqrt(2)/radioRigRel)
				operation *= 2.54 if @selectedUnit() is 'SI'
				$form.form('set value', "deflexionWester", operation.toFixed(3))
				#   maximo momento
				operation = 2.38*Math.sqrt(radioContacto*radioRigRel)
				operation *= 2.54 if @selectedUnit() is 'SI'
				$form.form('set value', "maxMomentoWester", operation.toFixed(2))

				# Calculo Loannides
				# c
				radioContacto /= 0.393701 if @selectedUnit() is 'SI'
				cLoannides = 1.772 * radioContacto
				$form.form('set value', "cLoann", cLoannides.toFixed(2))
				#   esfuerzo
				operation = (3*cargaSemieje/Math.pow(espesorLosa, 2))*(1-Math.pow(cLoannides/radioRigRel, 0.72))
				operation *= (21 / 3045) if @selectedUnit() is 'SI'
				$form.form('set value', "esfuerzoLoann", operation.toFixed(2))
				#   deflexion
				operation = (cargaSemieje/(moduloReaccion*Math.pow(radioRigRel, 2)))*(1.205 - 0.69*(cLoannides/radioRigRel))
				operation *= 2.54 if @selectedUnit() is 'SI'
				$form.form('set value', "deflexionLoann", operation.toFixed(3))
				#   maximo momento
				operation = 1.8*Math.pow(cLoannides, 0.32)*Math.pow(radioRigRel, 0.59)
				operation *= 2.54 if @selectedUnit() is 'SI'
				$form.form('set value', "maxMomentoLoann", operation.toFixed(2))

				# Calculo Esfuerzo Interior
				#   b
				if radioContacto >= 1.724*espesorLosa
					b = radioContacto
				else
					b = -0.675*espesorLosa + Math.sqrt(1.6*Math.pow(radioContacto, 2)+Math.pow(espesorLosa, 2))

				b *= 2.54 if @selectedUnit() is 'SI'
				$form.form('set value', "b", b.toFixed(2))
				# esfuerzo
				operation = (3*cargaSemieje*(1+relacionPoisson))*(Math.log(radioRigRel/b)+0.6159)/(2*Math.PI*Math.pow(espesorLosa, 2))
				operation *= (21 / 3045) if @selectedUnit() is 'SI'
				$form.form('set value', "esfuerzo", operation.toFixed(2))
				# deflexion
				operation = cargaSemieje / (8*moduloReaccion*Math.pow(radioRigRel, 2))*(Math.pow((radioContacto / radioRigRel), 2)*(1 / (2*Math.PI))*(Math.log(radioContacto / (2*radioRigRel))-0.673)+1)
				operation *= 2.54 if @selectedUnit() is 'SI'
				$form.form('set value', "deflexion", operation.toFixed(4))

				# Calculo Esfuerzo en el borde
				#   esfuerzo circulo
				operation = ((3*cargaSemieje*(1+relacionPoisson))/(Math.PI*Math.pow(espesorLosa, 2)*(3+relacionPoisson)))*(Math.log(moduloElasticidad*Math.pow(espesorLosa, 3)/(100*moduloReaccion*Math.pow(radioContacto, 4)))+1.84-(4*relacionPoisson/3)+((1-relacionPoisson)/2)+(1.18*radioContacto*(1+2*relacionPoisson)/radioRigRel))
				operation *= (21 / 3045) if @selectedUnit() is 'SI'
				$form.form('set value', "esfuerzoCirculo", operation.toFixed(2))
				#   deflexion circulo
				operation = (0.431*cargaSemieje)*(1-(0.82*(radioContacto/radioRigRel)))/(moduloReaccion*radioRigRel*radioRigRel)
				operation *= 2.54 if @selectedUnit() is 'SI'
				$form.form('set value', "deflexionCirculo", operation.toFixed(4))
				#   esfuerzo semicirculo
				operation = ((3*cargaSemieje*(1+relacionPoisson))/(Math.PI*Math.pow(espesorLosa, 2)*(3+relacionPoisson)))*(Math.log(moduloElasticidad*Math.pow(espesorLosa, 3)/(100*moduloReaccion*Math.pow(radioContacto, 4)))+3.84-(4*relacionPoisson/3)+(radioContacto*(1+2*relacionPoisson)/(2*radioRigRel)))
				operation *= (21 / 3045) if @selectedUnit() is 'SI'
				$form.form('set value', "esfuerzoSemicirculo", operation.toFixed(2))
				#   deflexion semicirculo
				if relacionPoisson is 0.15
					operation = (0.431*cargaSemieje)*(1-(0.349*(radioContacto/radioRigRel)))/(moduloReaccion*radioRigRel*radioRigRel)
				else
					operation = (Math.sqrt(moduloElasticidad*Math.pow(espesorLosa, 3)*moduloReaccion))*(1-(0.323+0.17*relacionPoisson*radioContacto)/radioRigRel)
				# operation *= 2.54 if @selectedUnit() is 'SI'
				$form.form('set value', "deflexionSemicirculo", operation.toFixed(4))

				# Calculo Esfuerzo friccion
				esfuerzoFriccion = largoLosaMayor*densidadConcreto*coeficienteFriccion/2
				operation *= (2100 / 3045) if @selectedUnit() is 'SI'
				$form.form('set value', "esfuerzoFriccion", esfuerzoFriccion.toFixed(3))

				# Calculo Esfuerzo a tracción del concreto
				#   resistencia del concreto a presion
				$form.form('set value', "resistenciaConcretoTraccion", resistenciaConcreto.toFixed(2))
				#   resistencia traccion 3
				operation = 3*Math.sqrt(resistenciaConcreto)
				operation /= 10 if @selectedUnit() is 'SI'
				if operation > esfuerzoFriccion
					$form.form('set value', "resConcreto3Cumple", "Si")
				else
					$form.form('set value', "resConcreto3Cumple", "No")
				$form.form('set value', "resConcreto3", operation.toFixed(2))
				#   resistencia traccion 5
				operation = 5*Math.sqrt(resistenciaConcreto)
				operation /= 10 if @selectedUnit() is 'SI'
				if operation > esfuerzoFriccion
					$form.form('set value', "resConcreto5Cumple", "Si")
				else
					$form.form('set value', "resConcreto5Cumple", "No")
				$form.form('set value', "resConcreto5", operation.toFixed(2))


	setUnits: ->
		if @selectedUnit()
			if @selectedUnit().text is 'ENG'
				@longUnit('(plg)')
				@presionUnit('(psi)')
				@tempUnit('(°F)')
				@pesoUnit('(lb)')
				@densidadUnit('(pci)')
			else
				@longUnit('(cm)')
				@presionUnit('(Mpa)')
				@tempUnit('(°C)')
				@pesoUnit('(N)')
				@densidadUnit('(MN/m3)')
		else
			@longUnit('---')
			@presionUnit('---')
			@tempUnit('---')
			@pesoUnit('---')
			@densidadUnit('---')

	interpolate: (valueToInterpolate) ->
		console.log 'valute to interpolate'
		console.log valueToInterpolate
		L = [0, 0.5, 1, 1.5, 2, 2.5, 3, 3.5, 4, 4.5, 5, 5.5, 6, 6.5, 7, 7.5, 8, 8.5, 9, 9.5, 10, 10.5,
		 		11, 11.5, 12, 12.5, 13, 13.5, 14]
		C = [0, 0, 0.02, 0.05, 0.075, 0.15, 0.2, 0.3, 0.5, 0.65, 0.75, 0.85, 0.95, 1.02, 1.05, 1.075,
		 		1.085, 1.09, 1.09, 1.085, 1.075, 1.075, 1.06, 1.05, 1.05, 1.05, 1.05, 1.05, 1.05]

		lim1 = 0
		lim2 = 1
		sw = true

		while lim2 <= L.length and sw
			if not(L[lim1] < valueToInterpolate && valueToInterpolate < L[lim2])
				lim1++
				lim2++
			else
				sw = false

		if sw
			alert("Los valores para interpolar son muy altos, no se pudo hacer el cálculo")
			return 0
		else
			return ((valueToInterpolate - L[lim1])/(L[lim2] - L[lim1]))*(C[lim2] - C[lim1]) + C[lim1]

	setRulesValidation: ->
		emptyRule =
			type: 'empty'
			prompt: 'Campo vacío'
		numericRule =
			type: 'regExp[/^[0-9]+([.][0-9]+)?$/]'
			prompt: 'Debe ser numérico'
		myRules = [
			emptyRule
			numericRule
		]

		$('.ui.form').form(
				fields:
					unitType:
						identifier: 'unitType'
						rules: emptyRule
					espesorLosa:
						identifier: 'espesorLosa'
						rules: myRules
					moduloElasticidad:
						identifier: 'moduloElasticidad'
						rules: myRules
					relacionPoisson:
						identifier: 'relacionPoisson'
						rules: myRules
					moduloReaccion:
						identifier: 'moduloReaccion'
						rules: myRules
					cargaSemieje:
						identifier: 'cargaSemieje'
						rules: myRules
					largoLosaMayor:
						identifier: 'largoLosaMayor'
						rules: myRules
					largoLosaMenor:
						identifier: 'largoLosaMenor'
						rules: myRules
					coeficienteDilatacion:
						identifier: 'coeficienteDilatacion'
						rules: myRules
					gradienteTemperatura:
						identifier: 'gradienteTemperatura'
						rules: myRules
					densidadConcreto:
						identifier: 'densidadConcreto'
						rules: myRules
					coeficienteFriccion:
						identifier: 'coeficienteFriccion'
						rules: myRules
					resistenciaConcreto:
						identifier: 'resistenciaConcreto'
						rules: myRules
					# radioContacto:
					# 	identifier: 'radioContacto'
					# 	rules: [
					# 		numericRule
					# 	]
					# presionInflado:
					# 	identifier: 'presionInflado'
					# 	rules: [
					# 		numericRule
					# 	]
					# cargaSemiejeII:
					# 	identifier: 'cargaSemiejeII'
					# 	rules: [
					# 		numericRule
					# 	]
				inline: true
				keyboardShortcuts: false
			)




ko.applyBindings(new MainVM())
