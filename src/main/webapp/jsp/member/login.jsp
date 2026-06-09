<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ taglib uri="jakarta.tags.core" prefix="c" %>
<c:import url="../default/header.jsp"/>

<script type="text/javascript">
function loginCheck() {
    // 입력창에 접근하기 위해 값 가져오기
    var id = document.getElementById("userId").value;

    // [요청하신 기능] 아이디 길이 제한 : 6~10자 검사
    if(id.length < 6 || id.length > 10){
        alert('아이디는 6~10자로 입력하세요.');
        return; // 전송하지 않고 함수 종료
    }

    // 조건 만족 시 서버로 폼 전송 실행
    document.getElementById("loginForm").submit();
}
</script>

<div class="container" style="max-width: 450px;">
    <h2 style="text-align: center; color: #1E293B; margin-bottom: 30px;">로그인</h2>

    <form id="loginForm" action="/member/loginProc" method="post">
        <div style="margin-bottom: 20px;">
            <label style="font-weight: 600; color: #475569;">아이디</label>
            <input type="text" name="id" id="userId" class="form-control" placeholder="아이디를 입력하세요" required>
        </div>
        <div style="margin-bottom: 30px;">
            <label style="font-weight: 600; color: #475569;">비밀번호</label>
            <input type="password" name="pw" class="form-control" placeholder="비밀번호를 입력하세요" required>
        </div>
        <button type="button" onclick="loginCheck()" class="btn btn-primary" style="width: 100%; padding: 14px; font-size: 16px;">로그인</button>
    </form>

    <div style="text-align: center; margin-top: 25px;">
        <span style="color: #64748B;">아직 회원이 아니신가요?</span>
        <a href="/member/regist" style="color: #7AA2F7; text-decoration: none; font-weight: bold; margin-left: 5px;">회원가입</a>
    </div>
</div>

<c:import url="../default/footer.jsp"/>