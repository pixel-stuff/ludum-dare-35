﻿using UnityEngine;
using System.Collections;
using System;

public class AudioManager : MonoBehaviour {

	#region Singleton
	public static AudioManager m_instance;
	void Awake(){
		if(m_instance == null){
			//If I am the first instance, make me the Singleton
			m_instance = this;
			DontDestroyOnLoad(this.gameObject);
		}else{
			//If a Singleton already exists and you find
			//another reference in scene, destroy it!
			if(this != m_instance)
				Destroy(this.gameObject);
		}
	}
	#endregion Singleton

	[SerializeField]
	private string m_backgroundAudioSource;

	private static Transform m_transform;

	[SerializeField]
	private string m_fightMusic = "infect_it_theme_125bpm";


	public Action m_beatEvent;
	private float m_timeBetweenBeat = 60f / 125f;
	public float timeBetweenBeat{
		get { return m_timeBetweenBeat; }
	}

	// Use this for initialization
	void Start () {
		m_transform = this.transform;
		//Play (m_backgroundAudioSource);
	}

	public static void Play(string clipname){
		//Create an empty game object
		GameObject go = new GameObject ("Audio_" +  clipname);
		go.transform.parent = m_transform;
		//Load clip from ressources folder
		AudioClip newClip =  Instantiate(Resources.Load (clipname, typeof(AudioClip))) as AudioClip;

		//Add and bind an audio source
		AudioSource source = go.AddComponent<AudioSource>();
		source.clip = newClip;
		//Play and destroy the component
		source.Play();
		Destroy (go, newClip.length);

	}

	public void PlayFightMusic(){
		if (m_fightMusicGB == null) {
			m_fightMusicGB = new GameObject ("Audio_" + m_fightMusic);
			m_fightMusicGB.transform.parent = m_transform;
			//Load clip from ressources folder
			AudioClip newClip = Instantiate (Resources.Load (m_fightMusic, typeof(AudioClip))) as AudioClip;

			//Add and bind an audio source
			AudioSource source = m_fightMusicGB.AddComponent<AudioSource> ();
			source.clip = newClip;
			//Play and destroy the component
			source.Play ();
			InvokeRepeating ("BeatEvent", m_timeBetweenBeat * 1f, m_timeBetweenBeat);
		} else {
			m_fightMusicGB.GetComponent<AudioSource> ().time = 0f;
			m_fightMusicGB.GetComponent<AudioSource> ().Play ();
			InvokeRepeating ("BeatEvent", m_timeBetweenBeat * 1f, m_timeBetweenBeat);
		}
	}
	private GameObject m_fightMusicGB;

	public void BeatEvent(){
		if (m_beatEvent != null) {
			m_beatEvent ();
		}
	}

	public void StopBeat(){
		CancelInvoke ("BeatEvent");
		m_fightMusicGB.GetComponent<AudioSource> ().Pause ();
		//if (m_fightMusicGB != null) {
			//Destroy (m_fightMusicGB);
		//}
	}



	// Update is called once per frame
	void Update () {
	}
}
