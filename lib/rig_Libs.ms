/*
--Procedure:
input(Bone Chain,ClothMesh, Sway Control)
rename Bone Chain "skin_Bone"
Duplicate Bone Chain 2 times.
rename first duplicate as SwayBone
rename second dup as SimBone
Add Sway Controller to SwayBone
Create IK chain on SimBone
Attach IK target to nearest Vertex on Cloth Mesh
Add Cloth sim modifier to Cloth Mesh
Create a Sim_Sway Switch on Sway controller
Add Orient Constraint Target to Skin_Bone
Link Orient Constrain Weight to Sim_Sway Switch
--Procedure2:
ClothMesh as Mesh
Sway_Control as Text_Ob
fn CreateSwayBone
fn CreateIkChainBon -- with Iktarget create from vertexselection and attach to that vertex
From ClothMesh edge_selection do
(
    Skin_bon = create_Bone name:"Skin_Bone"
    Sway_bon = create_Bone name:"Sway_Bone"
    Sim_bon = create_IK_Chain_Bone name:"Sim_Bone"

    AddSimSwaySwitch Sway_Control Skin_bone Sway_Bon Sim_Bon
)
*/
--CreatePoint Helper
mapped fn addtoLayer ob layername =
(
	if classof layername == String do 
	(
		layer = LayerManager.getLayerFromName layername
		layer.addnode ob
	)
)
fn createPoRoot =
(
	Point name:"ofd_Sway+Sim_top" size:20.0 centermarker:false axistripod:false cross:false box:true constantscreensize:false wirecolor:(color 14 255 2)
)
fn createPo =
(
	Point name:(uniquename "ofd_sim_point") size:5.0 centermarker:false axistripod:false cross:true box:true constantscreensize:false wirecolor:(color 14 255 2)
)
--Duplicate Bone Hierachy
fn SelectChild sel =
(
	if isvalidnode sel do
	(
		local selarray = #()
		while sel != undefined do
			(
				append selarray sel
				sel=sel.children[1]
			)
		selArray
	)
)
fn renameList List prefix:"" base:"" suffix:"" =
(
	ar = List as Array 
	for i=1 to ar.count do
	(
		ar[i].name = (prefix+base+(formattedPrint (suffix as integer) format:"3.2d")+"_"+(formattedPrint i format:"3.3d"))
	)		
)
fn Breakname ob =
(
	FilterString ob.name "_"
)
fn DupBoneList ob boname boneColor:(color 255 0 0) prefix:1 =
(
	if isvalidnode ob do
	(
		n=ob
		local obarray = #()
		while n != undefined do
			(
				append obarray n
				n=n.children[1]
			)
		print obarray
		maxOps.cloneNodes obarray cloneType:#copy newNodes:&nols
		for o =1 to obarray.count do
		(
			
			NameBreak =  (FilterString obarray[o].name "_")
			BoneCol = NameBreak[(2+prefix)] as string
			BoneNum = NameBreak[(3+prefix)] as string
			nols[o].name = boname+"_"+BoneCol+"_"+BoneNum
			nols[o].taper = 10
			nols[o].backfin = off
			nols[o].wirecolor = Bonecolor
		)
		nols
	)
)
-- SetUp ChainIk
fn Set_Chain_IK layername bolist =
(
	p4list = #()
	iklist = #()
	for a=1 to bolist.count do (
		if a != bolist.count do (
			b=a+1
			ik1 = IKSys.ikChain bolist[a] bolist[b] (IKSys.solverName 1)
			ik1.transform.controller.goalSize = 5
			p4 = CreatePo()
			p4.pos = ik1.pos
			ik1.parent = p4
			append p4list p4
			append iklist ik1
			addtolayer ik1 layername
			addtolayer p4 layername
		)
	)
	#(p4list,iklist)
)
fn AttachObtoMesh obs Att_mesh =
(
  AttachObj = obs
  AttachTo = Att_mesh
  undo "AttachToNearVertex" on (
    if (isKindOf AttachTo Editable_mesh) then (
      for p in AttachObj do (
        pos1 = p.pos
        dtc = 100000
        local face = 1
        for j = 1 to (getNumFaces AttachTo) do (
          pos2 = meshop.getFaceCenter AttachTo j
          if (distance pos1 pos2) <= dtc then (
            dtc = (distance pos1 pos2)
            face = j
          )
        )
        p.pos.controller = Attachment ()
        p.pos.controller.node = AttachTo
        a = AttachCtrl.addNewKey p.pos.controller 0
        a.face = (face-1) with animate on at time 0 ()
        a.coord = [0.0,0.0] with animate on at time 0 ()
        dA = (distance pos1 p.pos)
        a.coord = [1.0,0.0] with animate on at time 0 ()
        dB = (distance pos1 p.pos)
        a.coord = [0.0,1.0] with animate on at time 0 ()
        dC = (distance pos1 p.pos)
        if (dA <= dB and dA <= dC) then (a.coord = [0.0,0.0] with animate on at time 0 ())
        if (dB <= dA and dB <= dC) then (a.coord = [1.0,0.0] with animate on at time 0 ())
        if (dC <= dB and dC <= dA) then (a.coord = [0.0,1.0] with animate on at time 0 ())
      )
    )
  )
)

fn AddSwayControllAttributes SwayController = 
(
	addModifier SwayController (EmptyModifier name:"Sway Attribute")
	local SwayCtrlCA = attributes Custom_Attributes (
		parameters main rollout:params (
			StartFrame type:#integer ui:StartFrame default:0
			EndFrame type:#integer ui:EndFrame default:60
			Cycle type:#integer ui:Cycle default:2
			Volume type:#float ui:Volume default:0.0
			Reverse type:#boolean ui:Reverse default:false
			ColumnInterval type:#float ui:ColumnInterval default:25.0
			RowInterval type:#float ui:RowInterval default:30.0
			YZtiming type:#float ui:YZtiming default:60.0
		)
		rollout params "Custom Attributes" (
			spinner StartFrame "Start Frame:" range:[-99999,99999,0] scale:1 fieldwidth:50 type:#integer align:#right
			spinner EndFrame "End Frame:" range:[-99999,99999,60] scale:1 fieldwidth:50 type:#integer align:#right
			spinner Cycle "Cycle:" range:[1,99999,2] scale:1 fieldwidth:50 type:#integer align:#right
			spinner Volume "Volume:" range:[-99999,99999,0.0] scale:0.1 fieldwidth:50 type:#float align:#right
			checkbox Reverse "Reverse" checked:false type:#boolean align:#right
			spinner ColumnInterval "Column Interval:" range:[-99999,99999,25.0] scale:0.1 fieldwidth:50 type:#float align:#right
			spinner RowInterval "Row Interval:" range:[-99999,99999,30.0] scale:0.1 fieldwidth:50 type:#float align:#right
			spinner YZtiming "YZtiming:" range:[-99999,99999,60.0] scale:0.1 fieldwidth:50 type:#float align:#right
		)
	)
	custAttributes.add SwayController.modifiers[1] SwayCtrlCA
)
fn addSwaySwitchAtt ob = (
	addModifier ob (EmptyModifier name:"Sway Sim Switch")
	local SwitchCa = attributes Custom_Attributes
	(
		parameters main rollout:params
		(
			SimAnimSwitch type:#float ui:SimAnimSwitchUI default:0.0
		)
		rollout params "Custom Attributes"
		(
			Slider SimAnimSwitchUI ": Sway <                > Sim :" range:[0,1,0.0] scale:0.1 fieldwidth:140 type:#float align:#center
		)
	)
	custAttributes.add ob.modifiers[("Sway Sim Switch")]  SwitchCa
)

fn createOCSwitch switchob ob tar1 tar2 =
(
	ob.rotation.controller = Orientation_Constraint()
	ob.rotation.controller.appendTarget tar1 100
	ob.rotation.controller.appendTarget tar2 100
	paramwire.Connect switchob.modifiers[#Sway_Sim_Switch].Custom_Attributes[#SimAnimSwitch] ob.rotation.controller[#Orientation_Weight_0] "1-SimAnimSwitch"
	paramwire.Connect switchob.modifiers[#Sway_Sim_Switch].Custom_Attributes[#SimAnimSwitch] ob.rotation.controller[#Orientation_Weight_1] "SimAnimSwitch"
)
fn checkname ob =
(
	for i in ob do 
	(
		NameBreak = (FilterString i.name "_")
		if NameBreak ==3 then true else 
		(
			MessageBox "Rename Skin Bone system to this format 'SkinBone_01_001'"
			false
		)
	)
)

fn SetSway boneList SwayCtr =
(
	undo "Assign Sway System" on (
		local row = 1
		for b in BoneList do (
			local col = 1
			while b != undefined do (
				-- rotation controller  list
				Try (
					b.rotation.controller = Euler_Xyz()
					b.rotation.controller = Rotation_list()
					b.rotation.controller.available.controller = Euler_xyz() 
					b.rotation.controller.setname 2 "Loopable_Sway"	
					b.rotation.controller.SetActive 1
				)
				Catch()
				-- assign script controller rotY
				local ystr = "COL = " + (col as string) + "\n"
				ystr += "DECAY = " + ((col*0.1) as string) + "\n"
				ystr += "ROW = " + (row as string) + "\n"
				ystr += "if reverse then direct_rot = -1\n"
				ystr += "else direct_rot = 1\n"
				ystr += "rad2deg = 3.14159265358979/180.0\n"
				ystr += "sin(F*direct_rot*(360.0/(Eframe-Sframe))*cycle + row_interval*ROW - col_interval*COL)*rad2deg * volume * DECAY"
				local yctrl = Float_Script()
				b[3][2][2][2].controller = yctrl
				yctrl.AddTarget "Sframe" SwayCtr.modifiers[#Sway_Attribute].Custom_Attributes[#StartFrame]
				yctrl.AddTarget "Eframe" SwayCtr.modifiers[#Sway_Attribute].Custom_Attributes[#EndFrame]
				yctrl.AddTarget "cycle" SwayCtr.modifiers[#Sway_Attribute].Custom_Attributes[#Cycle]
				yctrl.AddTarget "volume" SwayCtr.modifiers[#Sway_Attribute].Custom_Attributes[#Volume]
				yctrl.AddTarget "reverse" SwayCtr.modifiers[#Sway_Attribute].Custom_Attributes[#Reverse]
				yctrl.AddTarget "col_interval" SwayCtr.modifiers[#Sway_Attribute].Custom_Attributes[#ColumnInterval]
				yctrl.AddTarget "row_interval" SwayCtr.modifiers[#Sway_Attribute].Custom_Attributes[#RowInterval]
				yctrl.AddTarget "YZtiming" SwayCtr.modifiers[#Sway_Attribute].Custom_Attributes[#YZtiming]
				yctrl.script = ystr
				-- assign script controller rotZ
				local zstr = "COL = " + (col as string) + "\n"
				zstr += "DECAY = " + ((col*0.1) as string) + "\n"
				zstr += "ROW = " + (row as string) + "\n"
				zstr += "if reverse then direct_rot = -1\n"
				zstr += "else direct_rot = 1\n"
				zstr += "rad2deg = 3.14159265358979/180.0\n"
				zstr += "sin(F*direct_rot*(360.0/(Eframe-Sframe))*cycle + row_interval*ROW - col_interval*COL + YZtiming)*rad2deg * volume * DECAY"
				local zctrl = Float_Script()
				b[3][2][2][3].controller = zctrl
				zctrl.AddTarget "Sframe" SwayCtr.modifiers[#Sway_Attribute].Custom_Attributes[#StartFrame]
				zctrl.AddTarget "Eframe" SwayCtr.modifiers[#Sway_Attribute].Custom_Attributes[#EndFrame]
				zctrl.AddTarget "cycle" SwayCtr.modifiers[#Sway_Attribute].Custom_Attributes[#Cycle]
				zctrl.AddTarget "volume" SwayCtr.modifiers[#Sway_Attribute].Custom_Attributes[#Volume]
				zctrl.AddTarget "reverse" SwayCtr.modifiers[#Sway_Attribute].Custom_Attributes[#Reverse]
				zctrl.AddTarget "col_interval" SwayCtr.modifiers[#Sway_Attribute].Custom_Attributes[#ColumnInterval]
				zctrl.AddTarget "row_interval" SwayCtr.modifiers[#Sway_Attribute].Custom_Attributes[#RowInterval]
				zctrl.AddTarget "YZtiming" SwayCtr.modifiers[#Sway_Attribute].Custom_Attributes[#YZtiming]
				zctrl.script = zstr
				
				b = b.children[1]
				col += 1
			)
			row += 1
		)
	)
)
