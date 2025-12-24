using System.Collections;
using System.Collections.Generic;
using UnityEngine;

namespace FiveRabbitsDemo
{
    public class AnimatorParamatersChange : MonoBehaviour
    {

        private string[] m_buttonNames = new string[] { "Idle", "Run", "Dead" };

        private Animator m_animator;
        private int animatKey = 0;

        // Use this for initialization
        void Start()
        {
            m_animator = GetComponent<Animator>();
        }

        // Update is called once per frame
        void Update()
        {
            if (Input.GetKeyDown(KeyCode.J))
            {
                changeAnimtKey(1);
            }
            else if (Input.GetKeyDown(KeyCode.K))
            {
                changeAnimtKey(3);
            }
            // changeAnimtKey(0);
            // }
            // else
            // {
            //     changeAnimtKey(0);
            // }
            // Debug.Log(animatKey);

        }
        private void changeAnimtKey(int key)
        {
            if (key == animatKey) {
                animatKey = 0;
                m_animator.SetInteger("AnimIndex", animatKey);
                m_animator.SetTrigger("Next");
            };
            
            animatKey = key;
            m_animator.SetInteger("AnimIndex", animatKey);
            m_animator.SetTrigger("Next");
            
        }

    }
}
