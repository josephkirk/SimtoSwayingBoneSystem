--Import library
fileIn "OCN/lib/OCN_rig_Libs.ms"
--main
clearListener()
try (CloseRolloutFloater OCNRig_RF) catch()
--var
--UI def
rollout MainUI "Main"
(
	--localVariable
	local ctrlOb
	local clothob
	local Rigob = #()
	local chnameon = 0
	--UI
	label chnamelb "Character name:"
	edittext Chnametb align:#left
	label bonnamelb "Bone name:"
	edittext bonnametb align:#left text: "bon"
	label ctrloblb "Control Object: "
	pickbutton AddControllerbt "AddController" width:150 height:30
	label clothoblb "Cloth Object: "
	pickbutton pickClothbt "Select Cloth Object"  width:150 height:25
	label boneoblb "Top Bone: "
	listBox BoneObList --readOnly:true
	button addbonebt "Add" width:80 height:30 align:#left
	button removebonebt "Remove" width:80 height:30 align:#right offset:[0,-35]
	button Clearbonebt "Clear" width:100 height:30
	button CreateRigbt "Create Sim-Sway System" width:150 height:50 offset:[0,10]
	button RemoveRigbt "REMOVE ALL" width:150 height:50
	--function
	on AddControllerbt picked Ob do
	(
		if isvalidnode Ob do
		(
			if Ob.modifiers[#Sway_Attribute] ==undefined do AddSwayControllAttributes Ob
			if Ob.modifiers[#Sway_Sim_Switch] ==undefined do AddSwaySwitchAtt Ob
			AddControllerbt.text = Ob.name
			ctrlOB = ob
		)
	)
	on pickClothbt picked ob do
	(
		pickClothbt.text = ob.name
		clothOb=ob
	)
	on addbonebt pressed do (
		local nameList = #()
		AttachObj = selection as array
		for o in AttachObj do (append nameList o.name)
		BoneObList.items += nameList
	)
	on removebonebt pressed do (
		local nameList = BoneObList.items
		deleteItem nameList  BoneObList.selection
		BoneObList.items = nameList
	)
	on clearbonebt pressed do (
		BoneObList.items = #()
	)
	on createRigbt pressed do
	(
		if (superclassof ctrlOb) == shape and (classof clothob) == Editable_Mesh and BoneObList.items.count != 0 then
		(
			--declaration
			if chnametb.text != "" then 
			(
				chnameon=1
				chname = chnametb.text + "_" 
			)else
			(
				chnameon=0
				chname = chnametb.text
			)
			rigOb =#()
			obnamelist = #() 
			oblist = #()
			bonelist = #() 
			Swaybonelist =#()
			Swaybonetop =#()
			Simbonelist =#()
			currentlayerob = LayerManager.current
			currentlayer = currentlayerob.name
			swayBoneName = chname+ "bon-swy"
			simBoneName =chname+ "bon-sim"
			Ctrler = ctrlOb
			Clothmesh = clothOb
			--
			for i in BoneOblist.items do (
				append oblist (getNodebyName i)
			)
			-- single bone chain
			if oblist.Count==1 then
			(
				if querybox "There is only one Bone, Are you sure?" do
				(
				ob=oblist[1]
				BoRoot = CreatePoRoot()
				BoRoot.pos = ob.pos
				append RigOb BoRoot
				Bons = selectChild ob
				renameList Bons prefix:chname base:(bonnametb.text+"_") suffix:1
				BoRoot.name +="_"+ (BreakName ob)[2] as string
				for b in Bons do append obnamelist b.name
				SwayBones = dupBoneList ob swayBoneName bonecolor:(color 84 199 49) prefix:chnameon
				addtoLayer SwayBones currentlayer
				SimBones = dupBoneList ob simBoneName bonecolor:(color 177 88 27) prefix:chnameon
				addtoLayer SimBones currentlayer
				ob.parent = BoRoot
				Swaybones[1].parent = BoRoot
				SimBones[1].parent = BoRoot
				for bonnum=1 to Bons.count do
				(
					createOCSwitch Ctrler Bons[bonnum] SwayBones[bonnum] SimBones[bonnum]
					append RigOb SwayBones[bonnum]
					append RigOb SimBones[bonnum]
				)
				ofdlist = Set_Chain_IK simlayer Simbones
				renamelist ofdlist[1] prefix:chname base:"ofd_sim_Point_" 
				renamelist ofdlist[2] prefix:chname base:"IK_bon_sim_"
				AttachObtoMesh ofdlist[1] ClothMesh
				RigOb = RigOb+ ofdlist[1]+ofdlist[2]
				setSway Swaybones[1] Ctrler
				BoneOBList.items = obnamelist
				)
			) else --multiBone chain
			(
				if oblist.count>1 do
				(
					for i=1 to oblist.count do 
					(
						BoRooT = CreatePoRoot()
						
						BoRoot.pos = oblist[i].pos
						append RigOb BoRoot
						Bons = selectChild oblist[i]
						append bonelist Bons
						renameList Bons prefix:chname base:(bonnametb.text+"_") suffix:i
						BoRoot.name +="_"+ (Breakname oblist[i])[2] as string
						for b in Bons do append obnamelist b.name
						local SwayBones = dupBoneList oblist[i] swayBoneName bonecolor:(color 84 199 49) prefix:chnameon
						append Swaybonelist swaybones
						append Swaybonetop swaybones[1]
						local SimBones = dupBoneList oblist[i] simBoneName bonecolor:(color 177 88 27) prefix:chnameon
						append Simbonelist SimBones
						oblist[i].parent = BoRoot
						Swaybones[1].parent = BoRoot
						SimBones[1].parent = BoRoot
					)
					for bonChainnum=1 to bonelist.count do 
					(
						BoneChain = bonelist[BonChainNum]
						SwayBoneChain = Swaybonelist[BonChainNum]
						SimBoneChain = Simbonelist[BonChainNum]
						for bonnum=1 to BoneChain.count do
						(
							createOCSwitch Ctrler BoneChain[bonnum] SwayBoneChain[bonnum] SimBoneChain[bonnum]
							append RigOb SwayBoneChain[bonnum]
							append RigOb SimBoneChain[bonnum]
						)
						addtoLayer SwayBoneChain currentlayer
						addtoLayer SimBoneChain currentlayer
					)
					--createOCSwitch Ctrler bone
					for sbone in simbonelist do
					(
						ofdlist = Set_Chain_IK simlayer sbone
						AttachObtoMesh ofdlist[1] ClothMesh
						renamelist ofdlist[1] prefix:chname base:"ofd_sim_Point_" 
						renamelist ofdlist[2] prefix:chname base:"IK_bon_sim_"
						Rigob = Rigob+ ofdlist[1] +ofdlist[2]
					)
					--print swayboneLIst
					setSway Swaybonetop Ctrler
				)
			)
			BoneOBList.items = obnamelist
		) else messageBox "Please select Control(SplineShape/text),Cloth Object(EditableMesh) and add Bone"
	)
	on removeRigbt pressed do 
	(
		newnamelist =#()
		delete rigOb
		for objname in BoneOBList.items do 
		(
			
			obj = getnodebyname objname
			if (BreakName obj)[(3+chnameon)] =="001" do append newnamelist objname
			obj.rotation.controller = Euler_XYZ()
		)
		rigOb =#()
		BoneOBList.items = newnamelist
	)
)
--Create UI
OCNRig_RF = newrolloutfloater "OCN Sim Sway Rig" 200 560 1450 170
addRollout MainUi OCNRig_RF category:1 rolledUp:false
