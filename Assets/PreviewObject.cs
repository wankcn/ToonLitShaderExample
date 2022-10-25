using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class PreviewObject : MonoBehaviour
{
    public bool AutoRotate = false;
    public float sensity = 1.0f;
    Vector3 mPrevPos = Vector3.zero;
    Vector3 mPosDelta = Vector3.zero;

    void Update()
    {
        if (AutoRotate)
        {
            sensity = 0.1f;
            mPosDelta = Input.mousePosition - mPrevPos;
            transform.Rotate(transform.up, -sensity, Space.World);
        }
        else
        {
            sensity = 1f;
            if (Input.GetMouseButton(0))
            {
                mPosDelta = Input.mousePosition - mPrevPos;
                transform.Rotate(transform.up, -Vector3.Dot(mPosDelta, Camera.main.transform.right) * sensity * 0.1f,
                    Space.World);
            }
        }

        mPrevPos = Input.mousePosition;
    }
}