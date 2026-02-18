import 'package:field_work/config/theme/app_pallete.dart';
import 'package:field_work/features/member/controller/all_org_member_controller.dart';
import 'package:flutter/material.dart';
import '../../../widgets/animated_screen_wrapper.dart';
import '../widget/member_card.dart';

class AllOrgMemberScreen extends StatefulWidget {
  final String roomId;
  const AllOrgMemberScreen({super.key, required this.roomId});

  @override
  State<AllOrgMemberScreen> createState() => _AllOrgMemberScreenState();
}

class _AllOrgMemberScreenState extends State<AllOrgMemberScreen> {
  late final AllOrgMemberController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AllOrgMemberController(
      context: context,
      reloadData: reloadData,
      roomId: widget.roomId,
    );
    _controller.init();
  }

  void reloadData() => setState(() {});

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: (){
        FocusScope.of(context).unfocus();
      },
      child: Scaffold(
        appBar: _buildAppBar(),
        body: RefreshIndicator(
          onRefresh: _controller.onRefresh,
          child: AnimatedScreenWrapper(
            child: Column(
              children: [
                _buildSearchBar(),
                _buildFilterChips(),
                _controller.isLoading
                    ? const Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Pallete.primaryColor),
                      ),
                    )
                    :  Expanded(
                      child: _controller.members.isEmpty
                          ? AnimatedScreenWrapper(child: _buildEmptyState())
                          : AnimatedScreenWrapper(child: _buildMemberList()),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMemberList() {
    return ListView.builder(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      controller: _controller.scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _controller.members.length + 1,
      itemBuilder: (context, index) {
        if (index == _controller.members.length) {
          return _buildLoadMoreIndicator();
        }
        final member = _controller.members[index];
        return MemberCard(
          memberName: _controller.getInitials(member.fullName),
          memberRole: _controller.getRoleDisplay(member.role),
          member: member,
          onAdd:() => _controller.addMemberToRoom(member),
          isInRoom: _controller.isMemberInRoom(member.id ?? ''),
          isAdding: _controller.isAddingMember(member.id ?? ''),
        );
      },
    );
  }

  Widget _buildLoadMoreIndicator() {
    if (!_controller.isLoadingMore) return const SizedBox(height: 20);

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Pallete.primaryColor),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.6,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(30),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Pallete.primaryColor.withValues(alpha: 0.2),
                      Pallete.primaryColor.withValues(alpha: 0.05),
                    ],
                  ),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.group_add_outlined,
                  size: 80,
                  color: Pallete.primaryColor.withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'No Member Found',
                style: Theme.of(context).textTheme.titleLarge!.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Pull down to refresh or try a different search',
                style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      leading: IconButton(
        icon: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            Icons.arrow_back_ios_new,
            size: 18,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        onPressed: () => Navigator.pop(context),
      ),
      title: Text(
        'Organization Members',
        style: Theme.of(context).textTheme.titleMedium!.copyWith(
          fontWeight: FontWeight.w700,
        ),
      ),
      centerTitle: true,
      actions: [
        if (_controller.hasActiveFilters)
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Pallete.errorColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.filter_alt_off,
                size: 20,
                color: Pallete.errorColor,
              ),
            ),
            onPressed: _controller.clearFilters,
          ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: TextField(
        controller: _controller.searchController,
        onChanged: _controller.onSearch,
        decoration: InputDecoration(
          hintText: 'Search member...',
          prefixIcon: Icon(Icons.search, color: Pallete.primaryColor),
          suffixIcon: _controller.searchController.text.isNotEmpty
              ? IconButton(
                icon: Icon(Icons.clear),
                onPressed: () {
                  _controller.searchController.clear();
                  _controller.onSearch('');
                },
              )
              : null,
          filled: true,
          fillColor: Theme.of(context).colorScheme.surface,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    );
  }

  Widget _buildFilterChips() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      child: Row(
        children: [
          Icon(
            Icons.filter_list,
            size: 20,
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip('All', ''),
                  const SizedBox(width: 8),
                  _buildFilterChip('Managers', 'manager'),
                  const SizedBox(width: 8),
                  _buildFilterChip('Employees', 'employee'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String role) {
    final isSelected = _controller.selectedRole == role;

    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => _controller.onRoleFilter(role),
      backgroundColor: Theme.of(context).colorScheme.surface,
      selectedColor: Pallete.primaryColor.withValues(alpha: 0.15),
      checkmarkColor: Pallete.primaryColor,
      labelStyle: Theme.of(context).textTheme.bodySmall!.copyWith(
        color: isSelected ? Pallete.primaryColor : null,
        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isSelected
              ? Pallete.primaryColor.withValues(alpha: 0.5)
              : Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
          width: 1.5,
        ),
      ),
    );
  }

}