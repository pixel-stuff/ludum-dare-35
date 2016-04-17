﻿using UnityEngine;
using System.Collections;
using System;

[Serializable]
public struct StepFight{
	public string m_name;
	public Sprite m_sprite;
	public AudioClip m_sonReussi;
	public AudioClip m_sonFailed;
}


public class FightManager : MonoBehaviour {
	[Space(10)]
	public StepFight[] m_listStep;
	[Space(10)]
	public GameObject[] m_listGameObjectDisplayable;

	private bool m_isInit = false;


	public void InitFight(Cell cell){
		

		m_isInit = true;
	}


	// Use this for initialization
	void Start () {
	}
	
	// Update is called once per frame
	void Update () {
	
	}

	public void UpInput(){
		
		Debug.Log ("FIGHT UP");
	}

	public void DownInput(){
		Debug.Log ("FIGHT DOWN");
	}

	public void RightInput(){
		Debug.Log ("FIGHT RIGHT");
	}

	public void LeftInput(){
		Debug.Log ("FIGHT LEFT");
	}
}