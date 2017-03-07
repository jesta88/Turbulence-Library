//
//	Code repository for GPU noise development blog
//	http://briansharpe.wordpress.com
//	https://github.com/BrianSharpe
//
//	I'm not one for copyrights.  Use the code however you wish.
//	All I ask is that credit be given back to the blog or myself when appropriate.
//	And also to let me know if you come up with any changes, improvements, thoughts or interesting uses for this stuff. :)
//	Thanks!
//
//	Brian Sharpe
//	brisharpe CIRCLE_A yahoo DOT com
//	http://briansharpe.wordpress.com
//	https://github.com/BrianSharpe
//
//===============================================================================
//  Scape Software License
//===============================================================================
//
//Copyright (c) 2007-2012, Giliam de Carpentier
//All rights reserved.
//
//Redistribution and use in source and binary forms, with or without
//modification, are permitted provided that the following conditions are met: 
//
//1. Redistributions of source code must retain the above copyright notice, this
//   list of conditions and the following disclaimer. 
//2. Redistributions in binary form must reproduce the above copyright notice,
//   this list of conditions and the following disclaimer in the documentation
//   and/or other materials provided with the distribution. 
//
//THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
//ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
//WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
//DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNERS OR CONTRIBUTORS BE LIABLE 
//FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL 
//DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR 
//SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER 
//CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, 
//OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE 
//OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.;

Shader "Noise/3DCell Displaced" 
{
	Properties 
	{
		_Octaves ("Octaves", Float) = 8.0
		_Frequency ("Frequency", Float) = 1.0
		_Amplitude ("Amplitude", Float) = 1.0
		_Lacunarity ("Lacunarity", Float) = 1.92
		_Persistence ("Persistence", Float) = 0.8
		_Offset ("Offset", Vector) = (0.0, 0.0, 0.0, 0.0)
		_CellType ("Cell Type", Float) = 1.0
		_DistanceFunction ("Distance Function", Float) = 1.0
		_Transparency ("Transparency", Range(0.0, 1.0)) = 1.0
		_Displacement("Displacement", Float) = 1.0		_AnimSpeed("Animation Speed", Float) = 1.0		_LowColor("Low Color", Vector) = (0.0, 0.0, 0.0, 1.0)
		_HighColor("High Color", Vector) = (1.0, 1.0, 1.0, 1.0)

	}

	CGINCLUDE
		//
		//	FAST32_hash
		//	A very fast hashing function.  Requires 32bit support.
		//	http://briansharpe.wordpress.com/2011/11/15/a-fast-and-simple-32bit-floating-point-hash-function/
		//
		//	The hash formula takes the form....
		//	hash = mod( coord.x * coord.x * coord.y * coord.y, SOMELARGEFLOAT ) / SOMELARGEFLOAT
		//	We truncate and offset the domain to the most interesting part of the noise.
		//	SOMELARGEFLOAT should be in the range of 400.0->1000.0 and needs to be hand picked.  Only some give good results.
		//	3D Noise is achieved by offsetting the SOMELARGEFLOAT value by the Z coordinate
		//
		float4 FAST32_hash_3D_Cell( float3 gridcell )	//	generates 4 different random numbers for the single given cell point
		{
			//    gridcell is assumed to be an integer coordinate
		
			//	TODO: 	these constants need tweaked to find the best possible noise.
			//			probably requires some kind of brute force computational searching or something....
			const float2 OFFSET = float2( 50.0, 161.0 );
			const float DOMAIN = 69.0;
			const float4 SOMELARGEFLOATS = float4( 635.298681, 682.357502, 668.926525, 588.255119 );
			const float4 ZINC = float4( 48.500388, 65.294118, 63.934599, 63.279683 );
		
			//	truncate the domain
			gridcell.xyz = gridcell - floor(gridcell * ( 1.0 / DOMAIN )) * DOMAIN;
			gridcell.xy += OFFSET.xy;
			gridcell.xy *= gridcell.xy;
			return frac( ( gridcell.x * gridcell.y ) * ( 1.0 / ( SOMELARGEFLOATS + gridcell.zzzz * ZINC ) ) );
		}
		static const int MinVal = -1;
		static const int MaxVal = 1;
		float Cellular3D(float3 xyz, int cellType, int distanceFunction) 
		{
			int xi = int(floor(xyz.x));
			int yi = int(floor(xyz.y));
			int zi = int(floor(xyz.z));
		 
			float xf = xyz.x - float(xi);
			float yf = xyz.y - float(yi);
			float zf = xyz.z - float(zi);
		 
			float dist1 = 9999999.0;
			float dist2 = 9999999.0;
			float dist3 = 9999999.0;
			float dist4 = 9999999.0;
			float3 cell;
		 
			for (int z = MinVal; z <= MaxVal; z++) {
				for (int y = MinVal; y <= MaxVal; y++) {
					for (int x = MinVal; x <= MaxVal; x++) {
						cell = FAST32_hash_3D_Cell(float3(xi + x, yi + y, zi + z)).xyz;
						cell.x += (float(x) - xf);
						cell.y += (float(y) - yf);
						cell.z += (float(z) - zf);
						float dist = 0.0;
						if(distanceFunction <= 1)
						{
							dist = sqrt(dot(cell, cell));
						}
						else if(distanceFunction > 1 && distanceFunction <= 2)
						{
							dist = dot(cell, cell);
						}
						else if(distanceFunction > 2 && distanceFunction <= 3)
						{
							dist = abs(cell.x) + abs(cell.y) + abs(cell.z);
							dist *= dist;
						}
						else if(distanceFunction > 3 && distanceFunction <= 4)
						{
							dist = max(abs(cell.x), max(abs(cell.y), abs(cell.z)));
							dist *= dist;
						}
						else if(distanceFunction > 4 && distanceFunction <= 5)
						{
							dist = dot(cell, cell) + cell.x*cell.y + cell.x*cell.z + cell.y*cell.z;	
						}
						else if(distanceFunction > 5 && distanceFunction <= 6)
						{
							dist = pow(abs(cell.x*cell.x*cell.x*cell.x + cell.y*cell.y*cell.y*cell.y + cell.z*cell.z*cell.z*cell.z), 0.25);
						}
						else if(distanceFunction > 6 && distanceFunction <= 7)
						{
							dist = sqrt(abs(cell.x)) + sqrt(abs(cell.y)) + sqrt(abs(cell.z));
							dist *= dist;
						}
						if (dist < dist1) 
						{
							dist4 = dist3;
							dist3 = dist2;
							dist2 = dist1;
							dist1 = dist;
						}
						else if (dist < dist2) 
						{
							dist4 = dist3;
							dist3 = dist2;
							dist2 = dist;
						}
						else if (dist < dist3) 
						{
							dist4 = dist3;
							dist3 = dist;
						}
						else if (dist < dist4) 
						{
							dist4 = dist;
						}
					}
				}
			}
		 
			if(cellType <= 1)	// F1
				return dist1;	//	scale return value from 0.0->1.333333 to 0.0->1.0  	(2/3)^2 * 3  == (12/9) == 1.333333
			else if(cellType > 1 && cellType <= 2)	// F2
				return dist2;
			else if(cellType > 2 && cellType <= 3)	// F3
				return dist3;
			else if(cellType > 3 && cellType <= 4)	// F4
				return dist4;
			else if(cellType > 4 && cellType <= 5)	// F2 - F1 
				return dist2 - dist1;
			else if(cellType > 5 && cellType <= 6)	// F3 - F2 
				return dist3 - dist2;
			else if(cellType > 6 && cellType <= 7)	// F1 + F2/2
				return dist1 + dist2/2.0;
			else if(cellType > 7 && cellType <= 8)	// F1 * F2
				return dist1 * dist2;
			else if(cellType > 8 && cellType <= 9)	// Crackle
				return max(1.0, 10*(dist2 - dist1));
			else
				return dist1;
		}
		float CellNormal(float3 p, int octaves, float3 offset, float frequency, float amplitude, float lacunarity, float persistence, int cellType, int distanceFunction)
		{
			float sum = 0;
			for (int i = 0; i < octaves; i++)
			{
				float h = 0;
				h = Cellular3D((p+offset) * frequency, cellType, distanceFunction);
				sum += h*amplitude;
				frequency *= lacunarity;
				amplitude *= persistence;
			}
			return sum;
		}
	ENDCG

	SubShader 
	{
		Tags {"Queue"="Transparent"}

		Blend SrcAlpha OneMinusSrcAlpha
		
		CGPROGRAM
		#pragma surface surf Lambert vertex:vert alpha:fade
		#pragma glsl
		#pragma target 3.0
		
		fixed _Octaves;
		float _Frequency;
		float _Amplitude;
		float3 _Offset;
		float _Lacunarity;
		float _Persistence;
		fixed _CellType;
		fixed _DistanceFunction;
		fixed _Transparency;
		float _Displacement;		float _AnimSpeed;		fixed4 _LowColor;
		fixed4 _HighColor;


		struct Input 
		{
			float3 pos;

		};

		void vert (inout appdata_full v, out Input OUT)
		{
			UNITY_INITIALIZE_OUTPUT(Input, OUT);
			OUT.pos = float3(v.texcoord.xy, _Time.y * _AnimSpeed);
			float h = CellNormal(OUT.pos, _Octaves, _Offset, _Frequency, _Amplitude, _Lacunarity, _Persistence, _CellType, _DistanceFunction);
			v.vertex.xyz += v.normal * h * _Displacement;
		}

		void surf (Input IN, inout SurfaceOutput o) 
		{
			float h = CellNormal(IN.pos, _Octaves, _Offset, _Frequency, _Amplitude, _Lacunarity, _Persistence, _CellType, _DistanceFunction);
			
			h = h * 0.5 + 0.5;
			
			float4 color = float4(0.0, 0.0, 0.0, 0.0);
			color = lerp(_LowColor, _HighColor, h);

			o.Albedo = color.rgb;
			o.Alpha = h * _Transparency;
		}
		ENDCG
	}
	
	FallBack "Diffuse"
}