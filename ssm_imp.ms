/*
	3ds max's MaxScript for Importing Startopia for pc

	written by mariokart64n
	dec 4 2022
	
	Script written around a dozen file samples uploaded here
	https://forum.xentax.com/viewtopic.php?t=25669

	notes:
		file format is messy,
		they designate a byte which i believe defines the data that follows.
		but they dont provide a block size, so its not possible to skip
		to the next data block.
		
		that being said don't expect this to work on all files, it will 
		likely crash on most.
		
		I would project that either I interpreted the block wrong, or
		the file contains a sub type which throws everything into chaos...
		
		Write everything into a structure, each having a Read and Write 
		function.
		
		However the Build function only does some basic stuff, materials
		weights, animations, bones, all that is parsed into the structures
		but not brought into 3dsmax... format was too messy took up my
		weekend and don't wish to continue with this..
	
*/
clearListener()

try(destroyDialog ui_ssm)catch(ui_ssm)
rollout ui_ssm "SSM" (
	
	struct fmtSSM_Take (
		unk023 = "",
		unk024 = 0,
		fn read &f = (
			local result = false
			unk023 = readString f
			if unk023 != "" do (
				unk024 = readLong f #unsigned
				result = true
				)
			result
			),
		fn write &s = (
			writeString s unk023
			writeLong s unk024 #unsigned
			)
		)
	
	struct fmtSSM_Weight (
		/*int32_t*/  	index = -1, -- vertex index
		/*float*/    	weight = 0.0, -- weight
		/*int32_t*/  	bone_id = -1,
		fn read &f = (
			local result = true
			index = readLong f #signed
			if index > -1 then (
				weight = readFloat f
				bone_id = readLong f #signed
				) else (result = false)
			result
			),
		fn write &s = (
			writeLong s index #signed
			if index > -1 do (
				writeFloat s weight
				writeLong s bone_id #signed
				)
			)
		)
	
	struct fmtSSM_Face (
		/*
			the face data here is weird.
			it could be one face index is 24bits
			or maybe 16 or even 8 bits..
			
			not enough samples to make a better guess..
		*/
		face = #(0, 0, 0),
		flag = #(0, 0, 0), -- no clue, flag, weight, or colour?
		normal = [0.0, 0.0, 0.0], -- probably face normal
		fn read &f = (
			local b = 0
			local i = 1
			local j = 1
			
			for i = 1 to 3 do (
				face[i] = 0
				for j = 1 to 3 do (
					face[i] += ((readbyte f #unsigned) * (2 ^ (8 * (j - 1))))
					)
				
				flag[i] = readbyte f #unsigned
				)
			normal = [readFloat f, readFloat f, readFloat f]
			
			),
		fn write &s = (
			local i = 1
			local j = 1
			for i = 1 to 3 do (
				for j = 1 to 3 do (
					writeByte s (bit.and (bit.shift 0xAABBCC -((j - 1) * 8)) 0xFF) #unsigned
					)
				writeByte s flag[i] #unsigned
				)
			writeFloat s normal[1]
			writeFloat s normal[2]
			writeFloat s normal[3]
			)
		)
	
	struct fmtSSM_Vertex (
		index = 0,
		texcorrd = [0.0, 0.0, 0.0],
		normal = [0.0, 0.0, 0.0],
		fn read &f = (
			index = readLong f #signed
			texcorrd = [readFloat f, readFloat f, 0.0]
			normal = [readFloat f, readFloat f, readFloat f]
			),
		fn write &s = (
			writeLong s index #signed
			writeFloat s texcorrd[1]
			writeFloat s texcorrd[2]
			writeFloat s normal[1]
			writeFloat s normal[2]
			writeFloat s normal[3]
			)
		)
	
	struct fmtSSM_Texture (
		name = "",
		file = "",
		fn read &f = (
			local result = false
			name = readString f
			if name != "" do (
				file = readString f
				result = true
				)
			result
			),
		fn write &s = (
			if name.count > 0 then (
				writeString s name
				writeString s file
				) else (writeByte s 0)
			)
		)
	
	struct fmtSSM_Animation ( -- 60 bytes
		unk040 = #(), -- 195 floats
		fn read &f &count = (
			local i = 1
			local j = 1
			if count > 0 do (
				unk040[count] = #()
				for j = 1 to count do (
					unk040[j] = #()
					unk040[j][15] = 0.0
					for i = 1 to 15 do (
						unk040[j][i] = readFloat f
						)
					)
				)
			),
		fn write &s = (
			local i = 1
			local j = 1
			local count = unk040.count
			if count > 0 do (
				for j = 1 to count do (
					for i = 1 to 15 do (
						writeFloat s unk040[j][i]
						)
					)
				)
			)
		)
	
	struct fmtSSM_Bone ( -- 72 + n bytes
		name = "",
		unk027 = [0.0, 0.0, 0.0],
		unk028 = [0.0, 0.0, 0.0],
		unk029 = [0.0, 0.0, 0.0],
		unk030 = [0.0, 0.0, 0.0],
		unk031 = [0.0, 0.0, 0.0],
		unk032 = -1,
		unk033 = -1,
		unk034 = -1,
		
		fn read &f = (
			name = readString f
			unk027 = [readFloat f, readFloat f, readFloat f]
			unk028 = [readFloat f, readFloat f, readFloat f]
			unk029 = [readFloat f, readFloat f, readFloat f]
			unk030 = [readFloat f, readFloat f, readFloat f]
			unk031 = [readFloat f, readFloat f, readFloat f]
			unk032 = readLong f #signed
			unk033 = readLong f #signed
			unk034 = readLong f #signed
			),
		
		fn write &s = (
			writeString s name
			
			writeFloat s unk027[1]
			writeFloat s unk027[2]
			writeFloat s unk027[3]
			
			writeFloat s unk028[1]
			writeFloat s unk028[2]
			writeFloat s unk028[3]
			
			writeFloat s unk029[1]
			writeFloat s unk029[2]
			writeFloat s unk029[3]
			
			writeFloat s unk030[1]
			writeFloat s unk030[2]
			writeFloat s unk030[3]
			
			writeFloat s unk031[1]
			writeFloat s unk031[2]
			writeFloat s unk031[3]
			
			writeLong s unk032 #signed
			writeLong s unk033 #signed
			writeLong s unk034 #signed
			)
		
		)
	
	struct fmtSSM_Light (
		name = "",
		parent = "",
		unk050 = [0.0, 0.0, 0.0],
		unk051 = [0.0, 0.0, 0.0],
		unk052 = [0.0, 0.0, 0.0],
		unk053 = 0.0,
		
		fn read &f = (
			name = readString f
			parent = readString f
			unk050 = [readFloat f, readFloat f, readFloat f]
			unk051 = [readFloat f, readFloat f, readFloat f]
			unk052 = [readFloat f, readFloat f, readFloat f]
			unk053 = readFloat f
			),
			
		fn write &s = (
			writeString s name
			writeString s parent
			writeFloat s unk050[1]
			writeFloat s unk050[2]
			writeFloat s unk050[3]
			writeFloat s unk051[1]
			writeFloat s unk051[2]
			writeFloat s unk051[3]
			writeFloat s unk052[1]
			writeFloat s unk052[2]
			writeFloat s unk052[3]
			writeFloat s unk053
			)
		
		)
	
	struct fmtSSM_Mesh (
		/*uint32_t*/           	vertex_count = 0,
		/*fmtSSM_Vertex[]*/ 	vertices = #(),
		/*uint32_t*/          	face_count = 0,
		/*fmtSSM_Face[]*/     	faces = #(),
		/*fmtSSM_Texture*/   	texture = fmtSSM_Texture(), -- ?
		
		/*uint32_t*/           	unk060 = 0,
		/*uint16_t*/           	unk061 = 0,
		/*uint8_t*/           	unk062 = 0,
		
		fn read &f = (
			
			-- hmm.. i donno if this is suppose to be here
			texture.read(&f)
			if texture.name != "" do (
				unk060 = readLong f #unsigned
				unk061 = readShort f #unsigned
				unk062 = readByte f #unsigned
				)
			
			vertices = #()
			face_count = #()
			
			vertex_count = readLong f #unsigned
			if vertex_count > 0 do (
				vertices[vertex_count] = fmtSSM_Vertex()
				for i = 1 to vertex_count do (
					vertices[i] = fmtSSM_Vertex()
					vertices[i].read(&f)
					)
				
				-- Read Faces
				face_count = readLong f #unsigned
				if face_count > 0 do (
					faces[face_count] = fmtSSM_Face()
					for i = 1 to face_count do (
						faces[i] = fmtSSM_Face()
						faces[i].read(&f)
						)
					)
				)
			),
		
		fn write &s = (
			
			texture.write(&s)
			if texture.name != "" do (
				writeLong s unk060 #unsigned
				writeShort s unk061 #unsigned
				writeByte s unk062 #unsigned
				)
			
			local i = 1
			
			writeLong s (vertex_count = vertices.count) #unsigned
			for i = 1 to vertex_count do (
				vertices[i].write(&s)
				)
			
			writeLong s (face_count = faces.count) #unsigned
			for i = 1 to face_count do (
				faces[i].write(&s)
				)
			)
		
		)
	
	struct fmtSSM_Model ( -- Type 1
		/*uint8_t*/            	count = 0, -- number of submeshes (materials)
		/*uint8_t*/            	unk005 = 0,
		/*uint16_t*/          	unk006 = 0,
		/*fmtSSM_Mesh[]*/   	submesh = #(),
		/*string[]*/          	unk013 = "", -- mesh name?
		/*string[]*/         	unk014 = "", -- parent?
		fn read &f = (
			
			count = readByte f #unsigned
			unk005 = readByte f #unsigned
			unk006 = readShort f #unsigned
			
			submesh = #()
			if count > 0 do (
				local i = 1
				submesh[count] = fmtSSM_Mesh()
				for i = 1 to count do (
					submesh[i] = fmtSSM_Mesh()
					submesh[i].read(&f)
					)
				
				unk013 = readString f
				unk014 = readString f
				)
			),
		
		fn write &s = (
			
			writeByte s (count = submesh.count) #unsigned
			writeByte s unk005 #unsigned
			writeShort s unk006 #unsigned
			
			local i = 1
			for i = 1 to count do (
				submesh[i].write(&s)
				)
			
			writeString s unk013
			writeString sunk014
			)
		)
	
	struct fmtSSM_Material ( -- Type 0
		/*fmtSSM_Texture*/   	texture = fmtSSM_Texture(),
		/*uint32_t*/          	boneArr_count = 0,
		/*fmtSSM_Bone[]*/    	boneArr = #(),
		/*uint32_t*/          	anim_count = 0,
		/*fmtSSM_Animation[]*/ 	anim = #(),
		/*float*/             	unk041 = 0,
		/*fmtSSM_Weight[]*/ 	weight = #(),
		/*fmtSSM_Take[]*/    	take = #(),
		
		fn read &f &fsize = (
			boneArr = #()
			anim = #()
			weight = #()
			
			-- if one then mesh is static?, otherwise contains additional data
			boneArr_count = readLong f #unsigned
			if boneArr_count > 1 then (
				
				local i = 1
				boneArr[boneArr_count] = fmtSSM_Bone()
				for i = 1 to boneArr_count do (
					boneArr[i] = fmtSSM_Bone()
					boneArr[i].read(&f)
					)
				
				anim_count = readLong f #unsigned
				if anim_count > 0 do (
					anim[anim_count] = fmtSSM_Animation()
					for i = 1 to anim_count do (
						anim[i] = fmtSSM_Animation()
						anim[i].read &f boneArr_count
						)
					)
				
				unk041 = readFloat f
				while ftell f < fsize do (
					append weight (fmtSSM_Weight())
					if not weight[weight.count].read(&f) do (
						exit
						)
					)
				
				while ftell f < fsize do (
					append take (fmtSSM_Take())
					if not take[take.count].read(&f) do (
						exit
						)
					)
				
				fseek f -1 #seek_cur -- hrm..
				) else (texture.read(&f))
			
			),
		
		fn write &f = (
			writeLong s (boneArr_count = boneArr) #unsigned
			if boneArr_count > 1 then (
				
				local i = 1
				for i = 1 to boneArr_count do (
					boneArr[i].write(&s)
					)
				
				
				writeLong s (anim_count = anim) #unsigned
				if anim_count > 0 do (
					for i = 1 to anim_count do (
						anim[i].write(&s)
						)
					)
				
				writeFloat s unk041
				
				for i = 1 to weight.count do (
					weight[i].write(&s)
					)
				
				for i = 1 to weight.count do (
					take[i].write(&s)
					)
				
				fseek s -1 #seek_cur
				) else (texture.write(&s))
			)
		)
	
	struct fmtSSM_VertBuf ( -- Type 8
		type = 0,
		count = 0,
		position = #(),
		
		fn read &f = (
			local result = true
			position = #()
			
			type = readByte f #unsigned
			case type of (
				0x00: (
					count = readLong f #unsigned
					if count > 0 do (
						position[count] = [0.0, 0.0, 0.0]
						local i = 1
						for i = 1 to count do (
							position[i] = [readFloat f, readFloat f, readFloat f]
							)
						)
					)
				--0x01: {}
				default: (
					result = false
					format "error: \tUnknown Buffer Type {%}\n" type
					)
				)
			result
			),
		
		fn write &s = (
			writeByte s type #unsigned
			case type of (
				0x00: (
					writeLong s (count = position.count) #unsigned
					count = readLong f #unsigned
					local i = 1
					for i = 1 to count do (
						writeFloat s position[i][1]
						writeFloat s position[i][2]
						writeFloat s position[i][3]
						)
					)
				)
			)
		
		)
		
	struct fmtSSM_Object ( -- Asset
		/*
			there are different object types, I could only document
			what wasin the few samples given so there are likely
			more undocumented types.
			
			types;
			- 0: Material
			- 1: mesh
			- 8: vertex positions
			--------------------
			- Bones
			- skinned mesh
			- animations
			- vertex blobs
			are amoung the chaos in the SSM format..
		*/
		/*uint8_t*/          	unk001 = 255, -- asset type? 8 = static mesh
		/*fmtSSM_VertBuf*/    	vertices = undefined,
		/*fmtSSM_Mesh*/      	model = undefined,
		/*fmtSSM_Material*/    	material = undefined,
		/*fmtSSM_Light*/      	light = undefined,
		
		fn read &f &fsize = (
			local result = true
			
			-- Read Header?
			unk001 = readByte f #unsigned
			case unk001 of (
				0x00: (
					model = fmtSSM_Model()
					model.read(&f)
					)
				0x01: (
					material = fmtSSM_Material()
					material.read &f fsize
					)
				0x08: (
					-- if followed by a 1, is not a mesh but a light?
					if readByte f == 1 then (
						light = fmtSSM_Light()
						light.read(&f)
						)
					else (
						fseek f -1 #seek_cur
						vertices = fmtSSM_VertBuf()
						result = vertices.read(&f)
						)
					)
				default: (
					result = false
					format "Error: \tReading Aborted Due to a weird number here [%]\n" unk001
					)
				)
			result
			),
		
		fn write &s = (
			if vertices != undefined then (
				writeByte s 8
				vertices.write(&s)
				)
			else if model != undefined then (
				writeByte s 0
				model.write(&s)
				)
			else if material != undefined then (
				writeByte s 1
				material.write(&s)
				)
			else if light != undefined then (
				writeByte s 8
				writeByte s 1
				light.write(&s)
				)
			)
		
		)
	
	struct fmtSSM (
		asset = #(),
		
		fn read &f = (
			
			-- Get File Size
			local pos = ftell f
			fseek f 0 #seek_end
			local fsize = ftell f
			fseek f pos #seek_set
			
			-- read until end of file is reached
			while ftell f < fsize do (
				append asset (fmtSSM_Object())
				if not (asset[asset.count].read &f fsize) do (
					format "Error: \tReading Aborted...\n"
					exit
					)
				)
			),
		
		fn write &s = (
			local i = 1
			for i = 1 to asset.count do (
				asset[i].write(&s)
				)
			),
		
		fn build clearScene:true impNormals:false fpath:"" = (
			if clearScene do (delete $*)
			
			local i = 1
			local count = asset.count
			local msh = undefined
			local vertArray = #()
			local faceArray = #()
			local uvwArray = #()
			local normArray = #()
			local tfaceArray = #() -- triangulated faces (series)
			local face_count = 0
			local v = 1
			local x = 1
			local j = 1
			local m = 1
			local n = 1
			
			-- Loop Through Each Asset
			for i = 1 to count do (
				
				
				
				
				if asset[i].unk001 == 8 and asset[i].vertices != undefined do (
					
					vertArray = #()
					if asset[i].vertices.position.count > 0 do (
						vertArray[asset[i].vertices.position.count] = [0.0, 0.0, 0.0]
						for v = 1 to asset[i].vertices.position.count do (
							vertArray[v] = [ \
								asset[i].vertices.position[v][1], \
								-asset[i].vertices.position[v][2], \
								-asset[i].vertices.position[v][3] \
								]
							)
						)
					
					-- jump to next valid mesh block
					for n = i to count do (
						
						
						if asset[n].unk001 == 0 and asset[n].model != undefined do (
							
							-- build any submeshes
							for m = 1 to asset[n].model.submesh.count do (
								
								faceArray = #()
								uvwArray = #()
								normArray = #()
								tfaceArray = #()
								
								face_count = asset[n].model.submesh[m].faces.count
								
								if face_count > 0 do (
									faceArray[face_count] = [1,1,1]
									tfaceArray[face_count] = [1,1,1]
									uvwArray[face_count * 3] = [0.0, 0.0, 0.0]
									for v = 1 to face_count do (
										x = (v - 1) * 3
										tfaceArray[v] = [1, 2, 3] + x
										faceArray[v] = [ \
											asset[n].model.submesh[m].vertices[asset[n].model.submesh[m].faces[v].face[1] + 1].index + 1, \
											asset[n].model.submesh[m].vertices[asset[n].model.submesh[m].faces[v].face[2] + 1].index + 1, \
											asset[n].model.submesh[m].vertices[asset[n].model.submesh[m].faces[v].face[3] + 1].index + 1 \
											]
										for j = 1 to 3 do (
											normArray[x + j] = [ \
												asset[n].model.submesh[m].vertices[asset[n].model.submesh[m].faces[v].face[j] + 1].normal[1], \
												asset[n].model.submesh[m].vertices[asset[n].model.submesh[m].faces[v].face[j] + 1].normal[2], \
												asset[n].model.submesh[m].vertices[asset[n].model.submesh[m].faces[v].face[j] + 1].normal[3] \
												]
											uvwArray[x + j] = [ \
												asset[n].model.submesh[m].vertices[asset[n].model.submesh[m].faces[v].face[j] + 1].texcorrd[1], \
												1.0 - asset[n].model.submesh[m].vertices[asset[n].model.submesh[m].faces[v].face[j] + 1].texcorrd[2], 0.0 \
												]
											)
										)
									)
								if faceArray.count > 0 do (
									msh = mesh vertices:vertArray faces:faceArray tverts:uvwArray
									buildTVFaces msh
									for v = 1 to tfaceArray.count do (setTVFace msh v tfaceArray[v])
									
									msh.backfacecull = on
									msh.displayByLayer = false
									msh.wirecolor = random (color 0 0 0) (color 255 255 255)
									for v = 1 to faceArray.count do setFaceSmoothGroup msh v 1
									
			-- 						if asset[n].model.submesh[m].material.count > 0 and asset[n].model.submesh[m].material[1].unk004 != "" do (
			-- 							msh.material = Standard diffuseMap:(Bitmaptexture fileName:(fpath + (getFilenameFile asset[n].model.submesh[m].material[1].unk004) + ".dds"))
			-- 							showTextureMap msh.material true
			-- 							)
									
									if impNormals do (
										local normID = #{}
										local normMod = Edit_Normals()
										addmodifier msh normMod ui:off
										normMod.selectBy = 1
										normMod.displayLength = 0
										
										msh.Edit_Normals.MakeExplicit selection:#{1..(vertArray.count)}
										
										normID = #{}
										--apply normals
										for x = 1 to normArray.count do (
											normID = #{} --free normID
											normMod.ConvertVertexSelection #{x} &normID
											for j in normID do (
												normMod.SetNormal j (normalize normArray[x])
												)
											)
										--collapseStack asset
										subobjectLevel = 0
										)
									)
								
								)
							
							exit
							)
						)
					)
				)
			)
		)
	
	
	button btn_open "Import"
	group "About" (
		label lbl_about "by mariokart64n" align:#left
		label lbl_date "Dec 4 2022" align:#left
		)
	
	local ssm = fmtSSM()
	
	fn read file = (
		if file != undefined and file != "" do (
			local f = try(fopen file "rb")catch(undefined)
			if f != undefined then (
				local ssm = fmtSSM()
				
				ssm.read(&f)
				ssm.build fpath:(getFilenamePath file)
				
				print "Done!"
				fclose f
				) else (format "error: \tfailed to open file {%}\n" file)
			)
		)
	
	on btn_open pressed do (read(getOpenFileName caption:"Open A File:" types:"ssm (*.ssm)|*.ssm|All|*.*|"))
	
	)
createDialog ui_ssm