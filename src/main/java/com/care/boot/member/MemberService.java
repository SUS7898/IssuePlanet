package com.care.boot.member;

import java.util.ArrayList;

import org.springframework.beans.factory.annotation.Autowired;
//import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.ui.Model;

import com.care.boot.PageService;

import jakarta.servlet.http.HttpSession;

@Service
public class MemberService {
	@Autowired private IMemberMapper mapper;
	@Autowired private HttpSession session;
	
	public String registProc(MemberDTO member) {
		if(member.getId() == null || member.getId().trim().isEmpty()) {
			return "아이디를 입력하세요.";
		}
		if(member.getPw() == null || member.getPw().trim().isEmpty()) {
			return "비밀번호를 입력하세요.";
		}
		if(member.getPw().equals(member.getConfirm()) == false) {
			return "두 비밀번호를 일치하여 입력하세요.";
		}
		if(member.getUserName() == null || member.getUserName().trim().isEmpty()) {
			return "이름을 입력하세요.";
		}
		
		MemberDTO check = mapper.login(member.getId());
		if(check != null) {
			return "이미 사용중인 아이디 입니다.";
		}
		
		/* 암호화 과정 */
		/*
		BCryptPasswordEncoder encoder = new BCryptPasswordEncoder();
		String secretPass = encoder.encode(member.getPw());
		member.setPw(secretPass);
		*/
		/*
			암호문 : $2a$10$HJ3CfbI4MxDDSM3emVsuNudQyQE5StjV7g/UGK2vSQZQRmGy23OXi
			암호문 길이: 60
			
			암호문 : $2a$10$nGmxZK6PVs.NV.QY.UX2T.OuGprkSwMs7FrNq6sOi1RfFPflQWUmO
			암호문 길이: 60
			
			pw 컬럼의 크기를 암호문 크기와 같거나 크게 변경
			ALTER TABLE db_quiz MODIFY pw varchar2(60);
			COMMIT;
		 */
		//System.out.println("암호문 : " + secretPass);
		//System.out.println("암호문 길이: " + secretPass.length());
		
		int result = mapper.registProc(member);
		if(result == 1)
			return "회원 등록 완료";
		
		return "회원 등록을 다시 시도하세요.";
	}
	
	
	public String loginProc(String id, String pw) {
		if(id == null || id.trim().isEmpty()) {
			return "아이디를 입력하세요.";
		}
		if(pw == null || pw.trim().isEmpty()) {
			return "비밀번호를 입력하세요.";
		}
		
		MemberDTO check = mapper.login(id);
		//BCryptPasswordEncoder encoder = new BCryptPasswordEncoder();
		//if(check != null && encoder.matches(pw, check.getPw()) == true) {
		if(check != null && check.getPw().equals(pw)) {
			session.setAttribute("id", check.getId());
			session.setAttribute("userName", check.getUserName());
			session.setAttribute("address", check.getAddress());
			session.setAttribute("mobile", check.getMobile());
			/*
			 * session.setAttribute("member", check);
			 * ${sessionScope.member.id}
			 * ${sessionScope.member.pw}
			 * ${sessionScope.member.userName}
			 */
			return "로그인 성공";
		}
		
		return "아이디 또는 비밀번호를 확인 후 다시 입력하세요.";
	}
	public void memberInfo(String select, String search, String cp, Model model) {
		int currentPage = 1;
		try{ currentPage = Integer.parseInt(cp); }catch(Exception e){}
		
		if(select == null) select = "";
		
		int pageBlock = 3; 
		int end = pageBlock * currentPage; 
		int begin = end - pageBlock + 1; 
		
		// [★수정] MariaDB의 LIMIT 처리를 위해 begin은 오프셋(0부터 시작)으로, end는 가져올 갯수로 넘기도록 변경합니다.
		// (단, member.xml의 쿼리가 LIMIT #{begin}, #{end} 로 작성되어 있어야 합니다.)
		ArrayList<MemberDTO> members = mapper.memberInfo(begin - 1, pageBlock, select, search);
		
		int totalCount = mapper.totalCount(select, search);
		if(totalCount == 0) return;
		
		String url = "memberInfo?select="+select+"&search="+search+"&currentPage=";
		String result = PageService.printPage(url, totalCount, pageBlock, currentPage);
		
		model.addAttribute("select", select);
		model.addAttribute("search", search);
		model.addAttribute("result", result);
		model.addAttribute("members", members);
	}
	
	public String userInfo(String id, Model model) {
		String sessionId = (String)session.getAttribute("id");
		if(sessionId == null)
			return "로그인 후 이용하세요.";
		
		if(sessionId.equals("admin") == false && sessionId.equals(id) == false) {
			return "본인의 아이디를 선택하세요.";
		}
		
		MemberDTO member = mapper.login(id);
		
		/* [★500 에러 방지용 안전장치 추가] */
		/* 탈퇴한 회원이거나 세션 정보가 DB와 불일치하여 member가 null인 경우 예외 처리 */
		if (member == null) {
			return "존재하지 않는 회원 정보입니다.";
		}
		
		if(member.getAddress() != null && member.getAddress().isEmpty() == false) {
			String[] address = member.getAddress().split(",");
			if(address.length >= 2) {
				model.addAttribute("postcode", address[0]);
				member.setAddress(address[1]);
				if(address.length == 3) {
					model.addAttribute("detailAddress", address[2]);
				}
			}
		}
		model.addAttribute("member", member);
		return "회원 검색 완료";
	}

	// 회원 정보 수정 서비스 로직 (비밀번호 변경 대응 및 암호화 주석 처리)
	/*
	 // 1. 암호화 객체 생성 부분 주석 처리
            // BCryptPasswordEncoder encoder = new BCryptPasswordEncoder();
            
            // 2. 암호화 매칭(matches) 대신 일반 문자열(평문) 비교로 변경
            // if(encoder.matches(member.getPw(), check.getPw())) {
            if(member.getPw() != null && member.getPw().equals(check.getPw())) {
                
                // 3. 비밀번호 재암호화해서 세팅하는 부분 주석 처리
                // member.setPw(encoder.encode(member.getPw()));
	 */
    public String updateProc(MemberDTO member, String newPw, String confirmNewPw) {
        MemberDTO check = mapper.login(member.getId());
        if(check != null) {
            
            // 1. 현재 비밀번호가 일치하는지 본인 확인 (평문 비교)
            if(member.getPw() != null && member.getPw().equals(check.getPw())) {
                
                // 2. 새 비밀번호 칸이 입력되었는지 검사
                if(newPw != null && !newPw.trim().isEmpty()) {
                    // 새 비밀번호와 새 비밀번호 확인 값이 일치하지 않는 경우 거부
                    if(!newPw.equals(confirmNewPw)) {
                        return "새 비밀번호가 서로 일치하지 않습니다.";
                    }
                    // 일치한다면 DTO의 pw를 새 비밀번호로 교체하여 DB로 전송 준비
                    member.setPw(newPw);
                } else {
                    // 새 비밀번호를 입력하지 않았다면 기존 비밀번호를 그대로 유지
                    member.setPw(check.getPw());
                }
                
                int result = mapper.updateProc(member);
                if(result == 1) {
                    return "회원 수정 완료";
                }
            }
        }
        return "현재 비밀번호를 확인 후 다시 시도하세요.";
    }

	public String deleteProc(MemberDTO member) {
		if(member.getPw() == null || member.getPw().trim().isEmpty()) {
			return "비밀번호를 입력하세요.";
		}
		if(member.getPw().equals(member.getConfirm()) == false) {
			return "두 비밀번호를 일치하여 입력하세요.";
		}
		
		MemberDTO check = mapper.login(member.getId());
		
		/* [수정] 회원 탈퇴 시 암호화 비교 대신 일반 문자열 equals 비교로 변경 */
		// BCryptPasswordEncoder encoder = new BCryptPasswordEncoder();
		// if(check != null && encoder.matches(member.getPw(), check.getPw()) == true) {
		if(check != null && check.getPw().equals(member.getPw())) {
			int result = mapper.deleteProc(member.getId());
			if(result == 1)
				return "회원 삭제 완료";
			return "회원 삭제를 다시 시도하세요.";
		}
		
		return "아이디 또는 비밀번호를 확인 후 입력하세요";
	}

}

















