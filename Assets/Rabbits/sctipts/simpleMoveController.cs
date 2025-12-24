using UnityEngine;

[RequireComponent(typeof(CharacterController))] // 自动添加CharacterController组件
public class simpleMoveController : MonoBehaviour
{
        [Header("移动与转向参数")]
    public float moveSpeed = 5f;      // 移动速度
    public float rotateSpeed = 90f;   // 转向速度（度/秒）

    [Header("重力与跳跃")]
    public float gravity = -9.81f;    // 重力加速度
    public float jumpHeight = 2f;     // 跳跃高度

    private CharacterController controller;
    private Vector3 velocity;         // 垂直方向速度（用于重力和跳跃）
    private bool isGrounded;          // 是否在地面

    // 地面检测（可选，用于跳跃）
    public Transform groundCheck;
    public float groundDistance = 0.4f;
    public LayerMask groundMask;
    void Start()
    {
        // 获取CharacterController组件（角色移动核心）
        controller = GetComponent<CharacterController>();

        // // 隐藏鼠标光标（并锁定到屏幕中心，适合第一人称）
        // Cursor.lockState = CursorLockMode.Locked;
    }

    void Update()
    {
        // 检测是否在地面上（通过球形碰撞检测）
         isGrounded = Physics.CheckSphere(groundCheck.position, groundDistance, groundMask);
        if (isGrounded && velocity.y < 0)
        {
            velocity.y = -2f; // 轻微贴地
        }

        // 1. A/D键控制转向（绕Y轴旋转）
        if (Input.GetKey(KeyCode.A))
        {
            // 向左转
            transform.Rotate(Vector3.up, -rotateSpeed * Time.deltaTime);
        }
        if (Input.GetKey(KeyCode.D))
        {
            // 向右转
            transform.Rotate(Vector3.up, rotateSpeed * Time.deltaTime);
        }

        // 2. W/S键控制前后移动（沿当前朝向）
        Vector3 move = Vector3.zero;
        if (Input.GetKey(KeyCode.W))
        {
            // 向前移动
            move = transform.forward;
        }
        if (Input.GetKey(KeyCode.S))
        {
            // 向后移动
            move = -transform.forward;
        }
        move.Normalize(); // 避免斜向移动加速（此处仅前后，可省略）

        // 3. 跳跃（空格键）
        if (Input.GetKeyDown(KeyCode.Space) && isGrounded)
        {
            velocity.y = Mathf.Sqrt(jumpHeight * -2f * gravity);
        }

        // 应用重力
        velocity.y += gravity * Time.deltaTime;
        move.y = velocity.y; // 加入垂直速度

        // 执行移动
        controller.Move(move * moveSpeed * Time.deltaTime);
    }


    // 绘制地面检测球的Gizmos（在Scene视图可视化）
    void OnDrawGizmos()
    {
        Gizmos.color = Color.red;
        Gizmos.DrawWireSphere(groundCheck.position, groundDistance);
    }
}