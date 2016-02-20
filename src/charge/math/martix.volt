module charge.math.matrix;

struct Matrix4x4f
{
public:
	union Union {
		float[4][4] m;
		float[16] a;
	}
	Union u;

public:

	void setToIdentity()
	{
		u.m[0][0] = 1.0f;
		foreach(ref v; u.a[1 .. $]) {
			v = 0.0f;
		}
		u.m[1][1] = 1.0f;
		u.m[2][2] = 1.0f;
		u.m[3][3] = 1.0f;
	}

	void setToOrtho(float left, float right,
	                float bottom, float top,
	                float nearval, float farval)
	{
		float xAdd = right + left;
		u.a[ 0] = 2.0f / (right - left);
		u.a[ 1] = 0.0f;
		u.a[ 2] = 0.0f;
		u.a[ 3] = xAdd == 0.0f ? 0.0f : -xAdd / (right - left);

		float yAdd = top + bottom;
		u.a[ 4] = 0.0f;
		u.a[ 5] = 2.0f / (top - bottom);
		u.a[ 6] = 0.0f;
		u.a[ 7] = yAdd == 0.0f ? 0.0f : -yAdd / (top - bottom);

		float zAdd = farval + nearval;
		u.a[ 8] = 0.0f;
		u.a[ 9] = 0.0f;
		u.a[10] = -2.0f / (farval - nearval);
		u.a[11] = zAdd == 0.0f ? 0.0f : -zAdd / (farval - nearval);

		u.a[12] = 0.0f;
		u.a[13] = 0.0f;
		u.a[14] = 0.0f;
		u.a[15] = 1.0f;
	}

	void transpose()
	{
		Matrix4x4f temp;

		temp.u.a[0] = u.a[ 0];
		temp.u.a[1] = u.a[ 4];
		temp.u.a[2] = u.a[ 8];
		temp.u.a[3] = u.a[12];
		temp.u.a[4] = u.a[ 1];
		temp.u.a[5] = u.a[ 5];
		temp.u.a[6] = u.a[ 9];
		temp.u.a[7] = u.a[13];
		temp.u.a[8] = u.a[ 2];
		temp.u.a[9] = u.a[ 6];
		temp.u.a[10] = u.a[10];
		temp.u.a[11] = u.a[14];
		temp.u.a[12] = u.a[ 3];
		temp.u.a[13] = u.a[ 7];
		temp.u.a[14] = u.a[11];
		temp.u.a[15] = u.a[15];

		this = temp;
	}
}
