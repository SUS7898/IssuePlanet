package com.care.boot.member;

import jakarta.servlet.http.HttpSession;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.servlet.mvc.support.RedirectAttributes;

@Controller
@RequestMapping("/member")
public class MemberController {
    
    @Autowired private MemberService service;
    @Autowired private HttpSession session;
    
    // 회원가입 페이지 이동
    @RequestMapping("/regist")
    public String regist() {
        return "member/regist";
    }
    
    // 회원가입 처리 로직
    @PostMapping("/registProc")
    public String registProc(MemberDTO member, Model model, RedirectAttributes ra) {
        String msg = service.registProc(member);
        
        if(msg.equals("회원 등록 완료")) {
            ra.addFlashAttribute("msg", msg);
            return "redirect:/index"; 
        }
        
        model.addAttribute("msg", msg);
        return "member/regist";
    }
    
    // 로그인 페이지 이동
    @RequestMapping("/login")
    public String login() {
        return "member/login";
    }
    
    // 로그인 처리 로직
    @PostMapping("/loginProc")
    public String loginProc(String id, String pw, Model model, RedirectAttributes ra) {
        String msg = service.loginProc(id, pw);
        if(msg.equals("로그인 성공")) {
            ra.addFlashAttribute("msg", msg);
            return "redirect:/index";
        }
        model.addAttribute("msg", msg);
        return "member/login";
    }
    
    // 로그아웃 처리 로직
    @RequestMapping("/logout")
    public String logout(RedirectAttributes ra) {
        session.invalidate();
        ra.addFlashAttribute("msg", "로그 아웃 완료");
        return "redirect:/";
    }

    // [복구] 내 정보 보기 조회 (대소문자 호환 경로 설정)
    @RequestMapping("/userInfo")
    public String userInfo(@RequestParam(value="id", required=false) String id, Model model) {
        // 관리자가 리스트에서 선택했거나, 일반 사용자가 세션 기반으로 접근했을 때 처리
        if (id == null || id.isEmpty()) {
            id = (String) session.getAttribute("id");
        }
        
        String msg = service.userInfo(id, model);
        if (msg.equals("회원 검색 완료")) {
            // 실제 JSP 파일명 구조인 UserInfo.jsp 대소문자 패턴 매칭 유의
            return "member/userInfo"; 
        }
        
        model.addAttribute("msg", msg);
        return "redirect:/index";
    }

    // [복구] 회원 전체 목록 조회 (관리자용)
    @RequestMapping("/memberInfo")
    public String memberInfo(@RequestParam(value="select", required=false) String select,
                             @RequestParam(value="search", required=false) String search,
                             @RequestParam(value="currentPage", defaultValue="1") String cp,
                             Model model) {
        // 서비스 단에 페이징 및 키워드 연동 데이터 위임
        service.memberInfo(select, search, cp, model);
        return "member/memberInfo";
    }

    // [복구] 회원 정보 수정 폼 이동
    @GetMapping("/update")
    public String update() {
        String sessionId = (String) session.getAttribute("id");
        if (sessionId == null) {
            return "redirect:/member/login";
        }
        return "member/update";
    }

    // [복구] 회원 정보 수정 처리 로직
    @PostMapping("/updateProc")
    public String updateProc(MemberDTO member, Model model, RedirectAttributes ra) {
        String msg = service.updateProc(member);
        if (msg.equals("회원 수정 완료")) {
            // 수정이 완료되면 세션 정보를 새 닉네임과 주소로 동기화 갱신합니다.
            session.setAttribute("userName", member.getUserName());
            session.setAttribute("address", member.getAddress());
            session.setAttribute("mobile", member.getMobile());
            
            ra.addFlashAttribute("msg", msg);
            return "redirect:/index";
        }
        model.addAttribute("msg", msg);
        return "member/update";
    }

    // [복구] 회원 탈퇴 폼 이동
    @GetMapping("/delete")
    public String delete() {
        String sessionId = (String) session.getAttribute("id");
        if (sessionId == null) {
            return "redirect:/member/login";
        }
        return "member/delete";
    }

    // [복구] 회원 탈퇴 처리 로직
    @PostMapping("/deleteProc")
    public String deleteProc(MemberDTO member, Model model, RedirectAttributes ra) {
        String sessionId = (String) session.getAttribute("id");
        if (sessionId == null) return "redirect:/member/login";
        
        member.setId(sessionId); // 보안을 위해 세션 아이디 강제 바인딩
        String msg = service.deleteProc(member);
        
        if (msg.equals("회원 삭제 완료")) {
            session.invalidate(); // 탈퇴 성공 시 세션 파기
            ra.addFlashAttribute("msg", msg);
            return "redirect:/index";
        }
        
        model.addAttribute("msg", msg);
        return "member/delete";
    }
}